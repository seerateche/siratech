import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/arabic_text.dart';
import '../../orders/domain/order.dart';
import '../domain/video_composer.dart';

class FfmpegComposer implements VideoComposer {
  /// Bundle Amiri.ttf at assets/fonts/Amiri.ttf — required for Arabic glyphs.
  static const _fontAsset = 'assets/fonts/Amiri.ttf';

  @override
  Future<String> compose({
    required Order order,
    required String audioPath,
    required List<String> photoPaths,
    required String outputPath,
    required int width,
    required int height,
    void Function(double progress)? onProgress,
  }) async {
    if (photoPaths.isEmpty) throw StateError('No photos to compose');
    if (!await File(audioPath).exists()) throw StateError('Audio file missing');

    final totalSec = await _audioDuration(audioPath);
    final seg = totalSec / photoPaths.length;
    final framesPerSlide = math.max(15, (seg * 30).round());
    final font = await _ensureFont();

    // ---- inputs ----
    final inputs = StringBuffer();
    for (final ph in photoPaths) {
      inputs.write('-i "${_q(ph)}" ');
    }
    inputs.write('-i "${_q(audioPath)}" ');

    // ---- Ken Burns per slide ----
    final parts = <String>[];
    for (var i = 0; i < photoPaths.length; i++) {
      parts.add(
        '[$i:v]scale=$width:$height:force_original_aspect_ratio=increase,'
        'crop=$width:$height,'
        'zoompan=z=\'min(1+0.0006*on,1.12)\':'
        'x=\'(iw-iw/zoom)/2+6*sin(on/80)\':'
        'y=\'(ih-ih/zoom)/2+4*cos(on/100)\':'
        'd=$framesPerSlide:s=${width}x$height:fps=30[s$i]',
      );
    }

    final concatIn = List.generate(photoPaths.length, (i) => '[s$i]').join();
    var chainLabel = '[cat]';

    // ---- captions (kept inside top/bottom safe zones for 9:16 & 1:1) ----
    final ar = L10n('ar');
    final captions = <String>[];
    if (order.clientName.trim().isNotEmpty) {
      captions.add(_drawtext(
        text: shapeArabic(order.clientName.trim()),
        font: font,
        size: (width * 0.075).round(),
        y: '(h*0.07)',
        color: '0xE6B65C',
        start: 0,
        end: seg * 0.95,
      ));
    }
    captions.add(_drawtext(
      text: shapeArabic(ar.t(order.occasion.l10nKey)),
      font: font,
      size: (width * 0.052).round(),
      y: '(h*0.155)',
      color: '0xE6B65C',
      start: seg * (photoPaths.length ~/ 2),
      end: seg * (photoPaths.length ~/ 2) + seg * 0.95,
    ));
    captions.add(_drawtext(
      text: 'Sira Tech • Creative Studio',
      font: font,
      size: (width * 0.032).round(),
      y: '(h*0.90)',
      color: '0xB98A3E',
      start: math.max(0, totalSec - 3),
      end: totalSec,
      outline: 1,
    ));

    final buffer = StringBuffer(parts.join(';'));
    buffer.write(';$concatIn concat=n=${photoPaths.length}:v=1:a=0[cat]');
    for (var c = 0; c < captions.length; c++) {
      final out = c == captions.length - 1 ? 'vout' : 'v$c';
      buffer.write(';[${c == 0 ? 'cat' : 'v${c - 1}'}]${captions[c]}[$out]');
    }

    final audioIdx = photoPaths.length;
    final cmd =
        '${inputs}-filter_complex "${buffer.toString()}" '
        '-map "[vout]" -map "$audioIdx:a" '
        '-c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p '
        '-c:a aac -b:a 192k -t ${totalSec.toStringAsFixed(2)} '
        '-movflags +faststart "${_q(outputPath)}"';

    final completer = Completer<String>();
    FFmpegKit.executeAsync(
      cmd,
      (session) async {
        final code = await session.getReturnCode();
        if (ReturnCode.isSuccess(code)) {
          completer.complete(outputPath);
        } else {
          completer.completeError(StateError(
            'FFmpeg failed: ${(await session.getLogsAsString())}',
          ));
        }
      },
      null,
      (Statistics stats) {
        final t = (stats.getTime() / 1000).clamp(0.0, totalSec);
        onProgress?.call((t / totalSec).clamp(0.0, 1.0));
      },
    );
    return completer.future;
  }

  String _drawtext({
    required String text,
    required String font,
    required int size,
    required String y,
    required String color,
    required double start,
    required double end,
    int outline = 2,
  }) {
    final fontArg = font.isEmpty ? '' : "fontfile='$_q(font)':";
    return "drawtext=${fontArg}text='${escapeDrawtext(text)}':fontsize=$size:"
        "fontcolor=$color:borderw=$outline:bordercolor=black@0.65:"
        "x=(w-text_w)/2:y=$y:"
        "enable='between(t,${start.toStringAsFixed(2)},${end.toStringAsFixed(2)})'";
  }

  String _q(String path) => path.replaceAll('"', '');

  Future<double> _audioDuration(String path) async {
    final info = await FFprobeKit.getMediaInformation(path);
    final d = double.tryParse(info.getMediaInformation()?.getDuration() ?? '');
    if (d == null || d <= 0) return 60;
    return d;
  }

  Future<String> _ensureFont() async {
    try {
      final data = await rootBundle.load(_fontAsset);
      final f = File(p.join(
        (await getTemporaryDirectory()).path,
        'SiraAmiri.ttf',
      ));
      if (!await f.exists()) {
        await f.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      return f.path;
    } catch (_) {
      // Font asset missing: drawtext falls back to the default font, which
      // cannot render Arabic. See README "Fonts".
      return '';
    }
  }
}

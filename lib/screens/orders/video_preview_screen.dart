import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../features/orders/domain/order.dart';
import '../../features/video/data/ffmpeg_composer.dart';
import '../../providers.dart';

class VideoPreviewScreen extends ConsumerStatefulWidget {
  final String orderId;
  const VideoPreviewScreen({super.key, required this.orderId});

  @override
  ConsumerState<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends ConsumerState<VideoPreviewScreen> {
  Order? _order;
  VideoPlayerController? _controller;
  bool _composing = false;
  double _progress = 0;
  int _w = 1080, _h = 1920;
  static const _aspects = [(1080, 1920), (1080, 1080), (1920, 1080)];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final o = await ref.read(orderRepositoryProvider).byId(widget.orderId);
    if (!mounted) return;
    setState(() => _order = o);
    if (o != null && o.videoPath.isNotEmpty && await File(o.videoPath).exists()) {
      await _initPlayer(o.videoPath);
    }
  }

  Future<void> _initPlayer(String path) async {
    _controller?.dispose();
    final c = VideoPlayerController.file(File(path));
    await c.initialize();
    c.setLooping(true);
    if (mounted) setState(() => _controller = c..play());
  }

  Future<void> _compose() async {
    final o = _order;
    if (o == null) return;
    final l = L10n(Localizations.localeOf(context).languageCode);
    setState(() {
      _composing = true;
      _progress = 0;
    });
    try {
      final dir = await ref.read(orderRepositoryProvider).orderDir(o.id);
      final out = p.join(dir, 'output_${_w}x$_h.mp4');
      await FfmpegComposer().compose(
        order: o,
        audioPath: o.audioPath,
        photoPaths: o.photoPaths,
        outputPath: out,
        width: _w,
        height: _h,
        onProgress: (v) => mounted ? setState(() => _progress = v) : null,
      );
      final updated = o.copyWith(videoPath: out, status: OrderStatus.video);
      await ref.read(orderRepositoryProvider).save(updated);
      setState(() => _order = updated);
      await _initPlayer(out);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.t('videoReady'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _composing = false);
    }
  }

  Future<void> _share() async {
    final v = _order?.videoPath;
    if (v != null && v.isNotEmpty && await File(v).exists()) {
      await Share.shareXFiles([XFile(v)], text: 'Sira Tech Creative Studio');
    }
  }

  Future<void> _saveToGallery() async {
    final v = _order?.videoPath;
    if (v == null || v.isEmpty) return;
    await Gal.putVideo(v, album: 'Sira Tech');
  }

  Future<void> _markDone() async {
    final o = _order;
    if (o == null) return;
    await ref.read(orderRepositoryProvider).save(o.copyWith(status: OrderStatus.done));
    if (mounted) context.go('/orders/${o.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(Localizations.localeOf(context).languageCode);
    final c = _controller;
    return GradientScaffold(
      appBar: AppBar(title: Text(l.t('composeVideo'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (c != null && c.value.isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            )
          else
            Container(
              height: 320,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.videocam_outlined, size: 64, color: AppColors.textMuted),
              ),
            ),
          if (c != null && c.value.isInitialized)
            IconButton(
              icon: Icon(
                c.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: AppColors.gold,
                size: 44,
              ),
              onPressed: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
            ),
          const SizedBox(height: 8),
          Text(l.t('pickAspect'), style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final a in _aspects)
                ChoiceChip(
                  label: Text(a.$2 > a.$1
                      ? l.t('aspect916')
                      : (a.$1 == a.$2 ? l.t('aspect11') : l.t('aspect169'))),
                  selected: _w == a.$1 && _h == a.$2,
                  onSelected: (_) => setState(() {
                    _w = a.$1;
                    _h = a.$2;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_composing) ...[
            LinearProgressIndicator(value: _progress, color: AppColors.gold),
            const SizedBox(height: 8),
            Text('${(_progress * 100).round()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: _composing ? null : _compose,
            icon: const Icon(Icons.movie_creation_outlined),
            label: Text(_composing ? l.t('composing') : l.t('composeVideo')),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.share),
                  label: Text(l.t('share')),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.gold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveToGallery,
                  icon: const Icon(Icons.download),
                  label: Text(l.t('saveToGallery')),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _markDone, child: Text(l.t('done'))),
        ],
      ),
    );
  }
}

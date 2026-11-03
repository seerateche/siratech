import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../features/orders/domain/order.dart';
import '../../providers.dart';

class NewOrderScreen extends ConsumerStatefulWidget {
  const NewOrderScreen({super.key});

  @override
  ConsumerState<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends ConsumerState<NewOrderScreen> {
  final _name = TextEditingController();
  final _details = TextEditingController();
  Occasion _occasion = Occasion.wedding;
  Mood _mood = Mood.joyful;
  List<XFile> _photos = [];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) setState(() => _photos = picked.take(8).toList());
  }

  Future<void> _save() async {
    final l = L10n(Localizations.localeOf(context).languageCode);
    if (_name.text.trim().isEmpty || _photos.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.t('requiredNamePhotos'))));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      var order = Order(
        id: const Uuid().v4(),
        clientName: _name.text.trim(),
        occasion: _occasion,
        mood: _mood,
        details: _details.text.trim(),
        createdAt: DateTime.now(),
      );
      await repo.save(order);
      final dir = p.join(await repo.orderDir(order.id), 'photos');
      await Directory(dir).create(recursive: true);
      final paths = <String>[];
      for (var i = 0; i < _photos.length; i++) {
        paths.add(await _normalizePhoto(_photos[i].path, p.join(dir, '$i.jpg')));
      }
      order = order.copyWith(photoPaths: paths);
      await repo.save(order);
      if (mounted) context.go('/orders/${order.id}/lyrics');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Downscale + fix EXIF orientation + encode JPEG (huge FFmpeg speedup).
  Future<String> _normalizePhoto(String src, String dest) async {
    final bytes = await File(src).readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) throw StateError('Cannot decode image');
    decoded = img.bakeOrientation(decoded);
    final scale = 1920 / math.max(decoded.width, decoded.height);
    if (scale < 1) {
      decoded = img.copyResize(
        decoded,
        width: (decoded.width * scale).round(),
        height: (decoded.height * scale).round(),
      );
    }
    await File(dest).writeAsBytes(img.encodeJpg(decoded, quality: 88));
    return dest;
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(Localizations.localeOf(context).languageCode);
    return GradientScaffold(
      appBar: AppBar(title: Text(l.t('newOrder'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: BrandLogo(scale: 0.9)),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.t('clientName')),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Occasion>(
            value: _occasion,
            decoration: InputDecoration(labelText: l.t('occasion')),
            items: Occasion.values
                .map((o) => DropdownMenuItem(value: o, child: Text(l.t(o.l10nKey))))
                .toList(),
            onChanged: (v) => setState(() => _occasion = v ?? _occasion),
          ),
          const SizedBox(height: 16),
          Text(l.t('mood'), style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: Mood.values
                .map(
                  (m) => ChoiceChip(
                    label: Text(l.t(m.l10nKey)),
                    selected: _mood == m,
                    onSelected: (_) => setState(() => _mood = m),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _details,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l.t('details'),
              hintText: l.t('detailsHint'),
            ),
          ),
          const SizedBox(height: 20),
          Text('${l.t('photos')} (${_photos.length}/8)'),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (_photos.length < 8)
                  GestureDetector(
                    onTap: _pickPhotos,
                    child: Container(
                      width: 92,
                      margin: const EdgeInsetsDirectional.only(end: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.gold),
                    ),
                  ),
                ..._photos.map(
                  (f) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(f.path),
                          width: 92, height: 92, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.t('next')),
          ),
        ],
      ),
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../features/orders/domain/order.dart';
import '../../providers.dart';

class MusicScreen extends ConsumerStatefulWidget {
  final String orderId;
  const MusicScreen({super.key, required this.orderId});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  Order? _order;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final o = await ref.read(orderRepositoryProvider).byId(widget.orderId);
    if (mounted) setState(() => _order = o);
  }

  Future<void> _pickAudio() async {
    setState(() => _picking = true);
    try {
      final r = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'aac', 'wav'],
      );
      final path = r?.files.single.path;
      final o = _order;
      if (path == null || o == null) return;
      final repo = ref.read(orderRepositoryProvider);
      final dest = await repo.importAsset(o.id, path, subDir: '', name: 'audio.mp3');
      final updated = o.copyWith(audioPath: dest, status: OrderStatus.audio);
      await repo.save(updated);
      if (mounted) context.go('/orders/${o.id}/video');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(Localizations.localeOf(context).languageCode);
    final o = _order;
    return GradientScaffold(
      appBar: AppBar(title: Text(l.t('musicStep'))),
      body: o == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (o.stylePrompt.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(o.stylePrompt,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(color: AppColors.text)),
                    ),
                  ),
                const SizedBox(height: 16),
                // Phase 3 placeholder — the pluggable provider slot.
                Opacity(
                  opacity: 0.5,
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_off, color: AppColors.textMuted),
                      title: Text(l.t('sunoSoon')),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _picking ? null : _pickAudio,
                  icon: _picking
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: Text(l.t('pickAudio')),
                ),
              ],
            ),
    );
  }
}

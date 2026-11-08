import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../features/orders/domain/order.dart';
import '../../providers.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Order? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final o = await ref.read(orderRepositoryProvider).byId(widget.orderId);
    if (mounted) setState(() => _order = o);
  }

  String get _nextRoute {
    final s = _order?.status ?? OrderStatus.draft;
    return switch (s) {
      OrderStatus.draft || OrderStatus.lyrics => '/orders/${widget.orderId}/lyrics',
      OrderStatus.audio => '/orders/${widget.orderId}/music',
      OrderStatus.video || OrderStatus.done => '/orders/${widget.orderId}/video',
    };
  }

  Future<void> _duplicate() async {
    final o = _order;
    if (o == null) return;
    final repo = ref.read(orderRepositoryProvider);
    final copy = Order(
      id: const Uuid().v4(),
      clientName: o.clientName,
      occasion: o.occasion,
      mood: o.mood,
      details: o.details,
      verse1: o.verse1,
      verse2: o.verse2,
      chorus: o.chorus,
      stylePrompt: o.stylePrompt,
      status: OrderStatus.draft,
      createdAt: DateTime.now(),
    );
    await repo.save(copy);
    final photos = <String>[];
    for (var i = 0; i < o.photoPaths.length; i++) {
      if (await File(o.photoPaths[i]).exists()) {
        photos.add(await repo.importAsset(copy.id, o.photoPaths[i],
            subDir: 'photos', name: '$i.jpg'));
      }
    }
    await repo.save(copy.copyWith(photoPaths: photos));
    if (mounted) context.go('/orders/${copy.id}');
  }

  Future<void> _delete() async {
    final l = L10n(Localizations.localeOf(context).languageCode);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.card,
        content: Text(l.t('confirmDelete')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.t('close'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.t('delete'))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(orderRepositoryProvider).delete(widget.orderId);
      if (mounted) context.go('/orders');
    }
  }

  Future<void> _resend() async {
    final v = _order?.videoPath;
    if (v != null && v.isNotEmpty && await File(v).exists()) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(v)], text: 'Sira Tech Creative Studio'),
      );
    }
  }

  Future<void> _saveGallery() async {
    final v = _order?.videoPath;
    if (v != null && v.isNotEmpty) await Gal.putVideo(v, album: 'Sira Tech');
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(Localizations.localeOf(context).languageCode);
    final o = _order;
    return GradientScaffold(
      appBar: AppBar(title: Text('${l.t('orderOf')} — ${o?.clientName ?? ''}')),
      body: o == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _row(l.t('occasion'), l.t(o.occasion.l10nKey)),
                _row(l.t('mood'), l.t(o.mood.l10nKey)),
                _row(l.t('createdAt'), DateFormat.yMMMd(l.lang).format(o.createdAt)),
                _row(l.t('orderStatus'), l.t(o.status.l10nKey)),
                if (o.details.isNotEmpty) _row(l.t('details'), o.details),
                if (o.lyricsText.isNotEmpty) ...[
                  const Divider(color: AppColors.cardBorder, height: 28),
                  Text(o.lyricsText,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: AppColors.text, height: 1.6)),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go(_nextRoute),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l.t('resume')),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resend,
                        icon: const Icon(Icons.share),
                        label: Text(l.t('resend')),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.gold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveGallery,
                        icon: const Icon(Icons.download),
                        label: Text(l.t('saveToGallery')),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.gold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _duplicate,
                        icon: const Icon(Icons.copy),
                        label: Text(l.t('duplicate')),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.gold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l.t('delete')),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(k, style: const TextStyle(color: AppColors.textMuted)),
            ),
            Expanded(child: Text(v, style: const TextStyle(color: AppColors.text))),
          ],
        ),
      );
}

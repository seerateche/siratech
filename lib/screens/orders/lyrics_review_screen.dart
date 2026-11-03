import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../features/orders/domain/order.dart';
import '../../providers.dart';

class LyricsReviewScreen extends ConsumerStatefulWidget {
  final String orderId;
  const LyricsReviewScreen({super.key, required this.orderId});

  @override
  ConsumerState<LyricsReviewScreen> createState() => _LyricsReviewScreenState();
}

class _LyricsReviewScreenState extends ConsumerState<LyricsReviewScreen> {
  Order? _order;
  late final _v1 = TextEditingController();
  late final _v2 = TextEditingController();
  late final _chorus = TextEditingController();
  late final _style = TextEditingController();
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final o = await ref.read(orderRepositoryProvider).byId(widget.orderId);
    if (!mounted || o == null) return;
    setState(() {
      _order = o;
      _v1.text = o.verse1;
      _v2.text = o.verse2;
      _chorus.text = o.chorus;
      _style.text = o.stylePrompt;
    });
  }

  Future<void> _generate() async {
    final l = L10n(Localizations.localeOf(context).languageCode);
    final gen = await ref.read(llmGeneratorProvider.future);
    if (gen == null || _order == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.t('needApiKey'))));
      return;
    }
    setState(() => _generating = true);
    try {
      final r = await gen.generate(_order!);
      setState(() {
        _v1.text = r.verse1;
        _v2.text = r.verse2;
        _chorus.text = r.chorus;
        _style.text = r.stylePrompt;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _saveAndContinue() async {
    final o = _order;
    if (o == null) return;
    await ref.read(orderRepositoryProvider).save(o.copyWith(
          verse1: _v1.text,
          verse2: _v2.text,
          chorus: _chorus.text,
          stylePrompt: _style.text,
          status: OrderStatus.lyrics,
        ));
    if (mounted) context.go('/orders/${o.id}/music');
  }

  Widget _editor(String label, TextEditingController c, {int lines = 4, bool rtl = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            maxLines: lines,
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            decoration: const InputDecoration(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(Localizations.localeOf(context).languageCode);
    final o = _order;
    return GradientScaffold(
      appBar: AppBar(title: Text(l.t('lyricsTitle'))),
      body: o == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _editor(l.t('verse1'), _v1),
                _editor(l.t('verse2'), _v2),
                _editor(l.t('chorus'), _chorus),
                const Divider(color: AppColors.cardBorder),
                const SizedBox(height: 6),
                Text(l.t('stylePromptTitle'),
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _style,
                  maxLines: 3,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: l.t('copyHint'),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy, color: AppColors.gold),
                      onPressed: () => Clipboard.setData(ClipboardData(text: _style.text)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _generating ? null : _generate,
                  icon: _generating
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_generating ? l.t('generating') : l.t('regenerate')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saveAndContinue,
                  child: Text(l.t('useContinue')),
                ),
              ],
            ),
    );
  }
}

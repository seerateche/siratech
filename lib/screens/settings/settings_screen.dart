import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _baseUrl = TextEditingController();
  final _apiKey = TextEditingController();
  final _model = TextEditingController();
  bool _obscure = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SecureStorage.read();
    if (!mounted) return;
    _baseUrl.text = s.baseUrl;
    _apiKey.text = s.apiKey;
    _model.text = s.model;
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final l = L10n(Localizations.localeOf(context).languageCode);
    await SecureStorage.write(LlmSettings(
      baseUrl: _baseUrl.text.trim(),
      apiKey: _apiKey.text.trim(),
      model: _model.text.trim(),
    ));
    ref.invalidate(settingsProvider);
    ref.invalidate(llmGeneratorProvider);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.t('saved'))));
    }
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(Localizations.localeOf(context).languageCode);
    return GradientScaffold(
      appBar: AppBar(title: Text(l.t('settings'))),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _baseUrl,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: l.t('llmBaseUrl'),
                    hintText: 'https://api.openai.com/v1',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _apiKey,
                  obscureText: _obscure,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: l.t('llmApiKey'),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _model,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: l.t('llmModel')),
                ),
                const SizedBox(height: 8),
                const Text(
                  'OpenAI-compatible endpoint: also works with OpenRouter, Groq, etc.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: _save, child: Text(l.t('save'))),
                const SizedBox(height: 24),
                Card(
                  child: SwitchListTile(
                    title: Text(l.t('language')),
                    subtitle: Text(Localizations.localeOf(context).languageCode == 'ar'
                        ? 'English'
                        : 'العربية'),
                    value: Localizations.localeOf(context).languageCode == 'ar',
                    onChanged: (v) {
                      ref.read(localeProvider.notifier).state =
                          v ? const Locale('ar') : const Locale('en');
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LlmSettings {
  final String baseUrl;
  final String apiKey;
  final String model;

  const LlmSettings({
    this.baseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.model = 'gpt-4o-mini',
  });

  bool get isConfigured => apiKey.trim().isNotEmpty;
}

class SecureStorage {
  SecureStorage._();
  static const _s = FlutterSecureStorage();

  static Future<LlmSettings> read() async {
    return LlmSettings(
      baseUrl: await _s.read(key: 'llm_base_url') ?? 'https://api.openai.com/v1',
      apiKey: await _s.read(key: 'llm_api_key') ?? '',
      model: await _s.read(key: 'llm_model') ?? 'gpt-4o-mini',
    );
  }

  static Future<void> write(LlmSettings v) async {
    await _s.write(key: 'llm_base_url', value: v.baseUrl);
    await _s.write(key: 'llm_api_key', value: v.apiKey);
    await _s.write(key: 'llm_model', value: v.model);
  }
}

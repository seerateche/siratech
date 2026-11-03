import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/secure_storage.dart';
import 'data/order_repository.dart';
import 'features/lyrics/data/llm_provider.dart';
import 'features/lyrics/domain/lyric_generator.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('ar'));

final orderRepositoryProvider = Provider<OrderRepository>((ref) => OrderRepository());

final settingsProvider = FutureProvider<LlmSettings>((ref) => SecureStorage.read());

final llmGeneratorProvider = FutureProvider<LyricGenerator?>((ref) async {
  final s = await ref.watch(settingsProvider.future);
  if (!s.isConfigured) return null;
  return OpenAiCompatibleLlm(baseUrl: s.baseUrl, apiKey: s.apiKey, model: s.model);
});

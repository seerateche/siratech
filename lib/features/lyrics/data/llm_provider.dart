import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/l10n/l10n.dart';
import '../../orders/domain/order.dart';
import '../domain/lyric_generator.dart';
import 'prompts.dart';

/// OpenAI-compatible chat endpoint — works with OpenAI, OpenRouter, Groq,
/// or any provider exposing /chat/completions. Configured in Settings.
class OpenAiCompatibleLlm implements LyricGenerator {
  final String baseUrl;
  final String apiKey;
  final String model;
  final Dio _dio;

  OpenAiCompatibleLlm({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  }) : _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));

  @override
  Future<GeneratedLyrics> generate(Order order) async {
    final res = await _dio.post(
      '$baseUrl/chat/completions',
      options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      data: {
        'model': model,
        'temperature': 0.9,
        'messages': [
          {'role': 'system', 'content': kSystemPrompt},
          {'role': 'user', 'content': buildLyricsUserPrompt(order, L10n('ar'))},
        ],
      },
    );
    final content = res.data['choices'][0]['message']['content'] as String;
    return GeneratedLyrics.fromJson(_extractJson(content));
  }

  Map<String, dynamic> _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('LLM did not return JSON');
    }
    final decoded = jsonDecode(raw.substring(start, end + 1));
    return decoded as Map<String, dynamic>;
  }
}

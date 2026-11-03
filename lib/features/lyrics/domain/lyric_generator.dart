import '../../orders/domain/order.dart';

class GeneratedLyrics {
  final String verse1;
  final String verse2;
  final String chorus;
  final String stylePrompt;

  const GeneratedLyrics({
    required this.verse1,
    required this.verse2,
    required this.chorus,
    required this.stylePrompt,
  });

  factory GeneratedLyrics.fromJson(Map<String, dynamic> j) => GeneratedLyrics(
        verse1: j['verse1'] as String? ?? '',
        verse2: j['verse2'] as String? ?? '',
        chorus: j['chorus'] as String? ?? '',
        stylePrompt: j['stylePrompt'] as String? ?? '',
      );
}

abstract class LyricGenerator {
  Future<GeneratedLyrics> generate(Order order);
}

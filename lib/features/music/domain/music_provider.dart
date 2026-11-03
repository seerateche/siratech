import 'dart:io';

/// Swap point for Phase 3: implement this against any licensed music
/// generation API (Suno paid tier, Beatoven.ai, Udio...) and register it in
/// [musicProviderRegistry]. Nothing else in the app changes.
abstract class MusicProvider {
  String get id;
  String get displayName;
  bool get requiresApiKey;

  /// Returns the path of the generated audio file on disk.
  Future<String> generate({
    required String lyrics,
    required String stylePrompt,
    required String outputDir,
    void Function(double progress)? onProgress,
  });
}

/// Phase 1 default: the business owner generates the song on a music
/// platform's website and imports the MP3 manually.
class ManualUploadMusicProvider implements MusicProvider {
  final String filePath;

  ManualUploadMusicProvider(this.filePath);

  @override
  String get id => 'manual';

  @override
  String get displayName => 'Manual MP3 upload';

  @override
  bool get requiresApiKey => false;

  @override
  Future<String> generate({
    required String lyrics,
    required String stylePrompt,
    required String outputDir,
    void Function(double progress)? onProgress,
  }) async {
    final dest = File('$outputDir/audio.mp3');
    await File(filePath).copy(dest.path);
    return dest.path;
  }
}

/// id -> factory. Add new providers here only.
final Map<String, MusicProvider Function()> musicProviderRegistry = {
  'manual': () => ManualUploadMusicProvider(''),
  // Phase 3:
  // 'suno': () => SunoMusicProvider(...),
  // 'beatoven': () => BeatovenMusicProvider(...),
};

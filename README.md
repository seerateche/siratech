# Sira Tech Creative Studio — Phase 1

Flutter app (Android-first, iOS-compatible) for a personalized-content business:
custom Egyptian-Arabic songs and videos for weddings, engagements, birthdays,
sebou3, graduations and dedications. Arabic RTL is the default UI; English
available via Settings.

## Pipeline (Phase 1 scope)
1. **New Order** — client name, occasion, mood, details, up to 8 photos
   (normalized + EXIF-fixed automatically).
2. **Lyrics** — LLM generation (OpenAI-compatible endpoint, configurable) of
   2 verses + chorus in Egyptian colloquial Arabic + an English `stylePrompt`
   for external music generators. Fully editable before continuing.
3. **Music** — manual MP3 upload (generated on the music platform of your
   choice). The `MusicProvider` interface + registry in
   `lib/features/music/domain/music_provider.dart` is the Phase 3 swap point
   for Suno / Beatoven / any licensed API — no other file changes needed.
4. **Video** — on-device FFmpeg: Ken-Burns slideshow timed to the audio, gold
   Arabic captions inside safe margins, 9:16 or 1:1 MP4 with faststart, preview,
   WhatsApp share sheet, save to gallery. Works fully offline.
5. **History** — local JSON store; resume, resend, duplicate, delete.
6. **Settings** — LLM base URL / API key / model in encrypted on-device storage
   (Android Keystore / iOS Keychain), plus the AR/EN toggle.

## Setup
**Want the installable APK?** Run `bash build_apk.sh` — it adds the font,
fixes the Gradle SDK version and outputs a release APK (details in BUILD_APK.md).

```bash
flutter pub get
flutter run            # Android device/emulator
```

### Fonts (one manual step — REQUIRED for Arabic video captions)
FFmpeg's drawtext cannot shape Arabic by itself. The app reshapes text in Dart
(`arabic_reshaper`) and needs an Arabic font file:
1. Download **Amiri** (SIL OFL): https://fonts.google.com/specimen/Amiri
2. Put `Amiri.ttf` in `assets/fonts/`
3. Uncomment the `assets:` block in `pubspec.yaml`
Without it, captions render as empty boxes.

### LLM configuration
Settings → API base URL (default `https://api.openai.com/v1`), API key, model.
Any OpenAI-compatible provider works: OpenAI, OpenRouter, Groq, etc.
The key never leaves the device except to the configured endpoint.

### Android notes
- `minSdk 24` is required by ffmpeg_kit. `build_apk.sh` and the GitHub
  workflow set it in `android/app/build.gradle` or `build.gradle.kts`.
- ffmpeg_kit 6.0.3 bundles FFmpeg 6.0; the upstream plugin is archived but the
  pub.dev build is stable. A community fork (`ffmpeg_kit` by arthenica
  successors) can be swapped later without code changes.

## Architecture
```
lib/
  core/         theme, l10n (hand-rolled, no codegen), secure storage, widgets
  data/         OrderRepository — JSON index + per-order asset folders
  features/
    orders/     domain models (Occasion, Mood, OrderStatus, Order)
    lyrics/     LyricGenerator interface + OpenAI-compatible impl + prompts
    music/      MusicProvider interface + ManualUploadMusicProvider + registry
    video/      VideoComposer interface + FfmpegComposer (zoompan, drawtext)
  screens/      new order, lyrics review, music, video preview,
                history list/detail, settings
```
Everything depends on the interfaces (`LyricGenerator`, `MusicProvider`,
`VideoComposer`), never on concrete providers — swap points are isolated.

### iOS (when you get there)
Add to `ios/Runner/Info.plist`:
- `NSPhotoLibraryUsageDescription` — to pick client photos
- `NSMicrophoneUsageDescription` — required by the camera/image pipeline
- `NSAppTransportSecurity` allows arbitrary loads only if you use a non-HTTPS
  LLM endpoint (not recommended).
Also bump `platform :ios, '12.0'` in the Podfile (ffmpeg_kit requirement).

## Known limitations (to address in Phase 2/3)
- Caption bidi: pure-Arabic or pure-Latin captions render correctly; mixed
  Arabic+digits strings are heuristically ordered, not full bidi. Keep
  captions pure Arabic.
- No cloud sync of orders.
- Auto music generation (Suno/Beatoven) is the planned Phase 3 — the manual
  upload path is the guaranteed fallback, always available.

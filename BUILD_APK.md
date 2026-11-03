# Building the APK yourself (15–25 min first time)

The sandbox that generated this project cannot compile Flutter, so the APK
must be built on your machine. One script does everything:

```bash
cd sira_tech_studio
bash build_apk.sh
```

The script will:
1. Verify Flutter is installed (install from https://docs.flutter.dev/get-started/install if not)
2. Download the Amiri font (required for Arabic video captions)
3. Enable `assets:` in pubspec.yaml and set `minSdkVersion 24`
4. Run `flutter pub get`
5. Build `build/app/outputs/flutter-apk/app-release.apk`

Copy that APK to the phone, allow "install from unknown sources", install.

## First-time Flutter setup on your PC (one time only)
1. Install Flutter SDK + Android Studio (SDK + licenses):
   `flutter doctor` must show all green checkmarks
   (`flutter doctor --android-licenses` accepts the licenses)
2. Connect the phone with USB debugging ON, or use an emulator

## Notes
- The APK is debug-signed. Fine for testing on your own devices. Before
  publishing to Play Store later, create a release signing key (`keytool`)
  and configure `android/key.properties` — do this in a packaging step.
- Build time on a mid-range PC: ~10 min first build, ~2–3 min after that.
- On Windows without bash: run the script's steps manually (each is one
  command).

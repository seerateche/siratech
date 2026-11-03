#!/usr/bin/env bash
# ============================================================
# Sira Tech Creative Studio — build a release APK in one shot
# Run from inside the project folder:  bash build_apk.sh
# ============================================================
set -e
cd "$(dirname "$0")"

echo "==> [1/6] Checking Flutter..."
flutter --version >/dev/null || { echo "Flutter not found. Install: https://docs.flutter.dev/get-started/install"; exit 1; }

echo "==> [2/6] Adding Amiri font (required for Arabic captions)..."
if [ ! -f assets/fonts/Amiri.ttf ]; then
  mkdir -p assets/fonts
  if command -v curl >/dev/null; then
    curl -L -o assets/fonts/Amiri.ttf \
      "https://github.com/google/fonts/raw/main/ofl/amiri/Amiri-Regular.ttf" \
      && echo "    downloaded Amiri.ttf"
  else
    echo "    !! Download Amiri.ttf manually from https://fonts.google.com/specimen/Amiri"
    echo "    !! put it in assets/fonts/ then re-run this script"
    exit 1
  fi
fi

echo "==> [2b/6] Regenerating missing native Android project files (gradle, wrapper, MainActivity)..."
if [ ! -f android/app/build.gradle ]; then
  flutter create --platforms=android --org com.siratech.studio .
fi

echo "==> [3/6] Enabling assets/fonts in pubspec.yaml..."
python3 - <<'PYEOF'
s = open("pubspec.yaml").read()
s = s.replace("  # assets:\n  #   - assets/fonts/Amiri.ttf",
              "  assets:\n    - assets/fonts/Amiri.ttf")
open("pubspec.yaml","w").write(s)
PYEOF

echo "==> [4/6] Setting minSdkVersion 24 in android/app/build.gradle..."
if [ -f android/app/build.gradle ]; then
  sed -i.bak 's/minSdkVersion [0-9]*/minSdkVersion 24/' android/app/build.gradle
  sed -i.bak 's/minSdk = [0-9]*/minSdk = 24/' android/app/build.gradle
fi

echo "==> [5/6] flutter pub get..."
flutter pub get

echo "==> [6/6] Building release APK..."
flutter build apk --release

echo ""
echo "============================================================"
echo "  ✅ APK ready:"
echo "  $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
echo "  Copy it to your phone and install."
echo "  (Allow 'install from unknown sources' on the phone.)"
echo "============================================================"

#!/usr/bin/env bash
# ============================================================
# Sira Tech Creative Studio — build a release APK in one shot
# Run from inside the project folder:  bash build_apk.sh
# ============================================================
set -e
cd "$(dirname "$0")"

echo "==> [1/4] Checking Flutter..."
flutter --version >/dev/null || { echo "Flutter not found. Install: https://docs.flutter.dev/get-started/install"; exit 1; }

echo "==> [2/4] Verifying Amiri font..."
if [ ! -f assets/fonts/Amiri.ttf ]; then
  mkdir -p assets/fonts
  if command -v curl >/dev/null; then
    curl -L -o assets/fonts/Amiri.ttf \
      "https://github.com/google/fonts/raw/main/ofl/amiri/Amiri-Regular.ttf" \
      && echo "    downloaded Amiri.ttf"
  fi
fi

echo "==> [3/4] flutter pub get..."
flutter pub get

echo "==> [4/4] Building release APK..."
flutter build apk --release

echo ""
echo "============================================================"
echo "  ✅ APK ready:"
echo "  $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
echo "  Copy it to your phone and install."
echo "  (Allow 'install from unknown sources' on the phone.)"
echo "============================================================"

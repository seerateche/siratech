#!/usr/bin/env bash
# ============================================================
# Sira Tech Creative Studio — build a release APK in one shot
# Run from inside the project folder:  bash build_apk.sh
# ============================================================
set -e
cd "$(dirname "$0")"

echo "==> [1/6] Checking Flutter..."
flutter --version >/dev/null || { echo "Flutter not found. Install: https://docs.flutter.dev/get-started/install"; exit 1; }
python3 - <<'PYEOF'
import re, subprocess, sys
out = subprocess.check_output(["flutter", "--version"], text=True, stderr=subprocess.STDOUT)
m = re.search(r"Flutter (\d+)\.(\d+)\.(\d+)", out)
if not m:
    sys.exit("Could not parse Flutter version:\n" + out)
ver = tuple(int(x) for x in m.groups())
need = (3, 38, 1)
if ver < need:
    sys.exit(
        "Flutter %s is too old. Need >= 3.38.1 (Dart >= 3.10) for share_plus 13 and file_picker 12."
        % ".".join(map(str, ver))
    )
print("    Flutter %s OK" % ".".join(map(str, ver)))
PYEOF

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
if [ ! -f android/app/build.gradle ] && [ ! -f android/app/build.gradle.kts ]; then
  flutter create --platforms=android --org com.siratech.studio .
fi

echo "==> [3/6] Enabling assets/fonts in pubspec.yaml..."
python3 - <<'PYEOF'
s = open("pubspec.yaml").read()
s = s.replace("  # assets:\n  #   - assets/fonts/Amiri.ttf",
              "  assets:\n    - assets/fonts/Amiri.ttf")
open("pubspec.yaml","w").write(s)
PYEOF

echo "==> [4/6] Setting minSdk 24 (ffmpeg_kit) in the app Gradle file..."
python3 - <<'PYEOF'
import re
from pathlib import Path

targets = [Path("android/app/build.gradle.kts"), Path("android/app/build.gradle")]
present = [p for p in targets if p.exists()]
if not present:
    raise SystemExit("android/app/build.gradle(.kts) missing after flutter create")

def floor_min_sdk(text: str, path: Path) -> str:
    new, n1 = re.subn(
        r"minSdk\s*=\s*(?:flutter\.minSdkVersion|\d+)",
        "minSdk = 24",
        text,
    )
    new, n2 = re.subn(
        r"minSdkVersion\s+(?:flutter\.minSdkVersion|\d+)",
        "minSdkVersion 24",
        new,
    )
    if n1 + n2 == 0 or ("minSdk = 24" not in new and "minSdkVersion 24" not in new):
        raise SystemExit(f"could not set minSdk 24 in {path}")
    return new

for path in present:
    path.write_text(floor_min_sdk(path.read_text(), path))
    print(f"    minSdk 24 set in {path}")
PYEOF

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

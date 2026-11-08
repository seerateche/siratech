import re
from pathlib import Path

pub_cache = Path.home() / ".pub-cache"
count = 0
if pub_cache.exists():
    for f in pub_cache.glob("hosted/pub.dev/**/android/build.gradle*"):
        try:
            txt = f.read_text(encoding="utf-8")
            # Upgrade compileSdk / compileSdkVersion below 36 to 36
            new_txt = re.sub(r'compileSdkVersion\s+(?:3[0-5]|[12]\d|\d\b)', 'compileSdkVersion 36', txt)
            new_txt = re.sub(r'compileSdk\s*=\s*(?:3[0-5]|[12]\d|\d\b)', 'compileSdk = 36', new_txt)
            if new_txt != txt:
                f.write_text(new_txt, encoding="utf-8")
                print(f"==> Patched compileSdk to 36 in: {f.name} ({f.parent.parent.name})")
                count += 1
        except Exception as e:
            print(f"Warning patching {f}: {e}")

print(f"==> Total pub-cache plugins patched: {count}")

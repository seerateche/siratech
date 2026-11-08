import os
import re
import subprocess
from pathlib import Path

print("==> Regenerating Android scaffolding with flutter create...")
subprocess.run(["flutter", "create", "--platforms=android", "--org", "com.siratech.sira_tech_studio", "."], check=True)

# 1. Patch minSdk to 24 in build.gradle(.kts)
for p in [Path("android/app/build.gradle.kts"), Path("android/app/build.gradle")]:
    if p.exists():
        txt = p.read_text(encoding="utf-8")
        txt = re.sub(r'minSdk\s*=\s*(?:flutter\.minSdkVersion|\d+)', 'minSdk = 24', txt)
        txt = re.sub(r'minSdkVersion\s+(?:flutter\.minSdkVersion|\d+)', 'minSdkVersion 24', txt)
        p.write_text(txt, encoding="utf-8")
        print(f"==> Patched minSdk 24 in {p}")

# 2. Add required permissions to AndroidManifest.xml
manifest_path = Path("android/app/src/main/AndroidManifest.xml")
if manifest_path.exists():
    mtxt = manifest_path.read_text(encoding="utf-8")
    perms = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>\n"""
    if "android.permission.INTERNET" not in mtxt:
        mtxt = mtxt.replace("<application", perms + "    <application")
        manifest_path.write_text(mtxt, encoding="utf-8")
        print("==> Added permissions to AndroidManifest.xml")

print("==> Android scaffolding prepared successfully!")

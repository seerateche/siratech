# Build the APK in the cloud — no PC setup needed (طريقة البناء من غير تسطيب حاجة)

Instead of installing Flutter on your machine, GitHub builds the APK for you
for free (~15 min, entirely from the browser).

## Steps

### 1) Create a free GitHub account
https://github.com/signup — works from the phone browser too.

### 2) Create a new repository
- Click "New repository", name it e.g. `sira-tech`, keep it **Public**
  (free Actions minutes), create.

### 3) Upload the project files
- On a PC: open the repo page → "uploading an existing file" → drag the
  **contents** of the unzipped `sira_tech_studio` folder (including the
  hidden `.github` folder — enable "show hidden files" or drag it too).
- On a phone: use the GitHub app or the desktop-mode browser; uploading many
  files is tedious on mobile, a PC or a friend's PC is easier.

### 4) Run the build
- Repo page → **Actions** tab → "Build APK" on the left → "Run workflow"
  (dropdown) → green **Run workflow** button.
- Wait ~10–15 minutes; a green checkmark means success.
  (If it's yellow for a while, that's normal — building takes time.)

### 5) Download the APK
- Open the finished run → **Artifacts** section → download `sira-tech-apk`
  (it's a zip containing `app-release.apk`).
- Send it to your phone (WhatsApp/email/USB) → install
  (allow "install from unknown sources").

## Alternative: Codemagic
https://codemagic.io — free tier, connect the same GitHub repo, add a
Flutter Android workflow, build, download. More setup than the GitHub path.

## Notes
- The APK is debug-signed: fine for installing on your own devices.
- Each "Run workflow" builds the current code in the repo — push updates
  then run again to get a newer APK.
- The workflow downloads the Amiri font and fixes Gradle settings itself;
  you don't need to do the manual steps from build_apk.sh.

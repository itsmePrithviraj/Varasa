# Run Varasa on macOS and Windows

## Fastest way to see the changes

Use Flutter **3.35.1** with bundled Dart **3.9.0**. The `.fvmrc` and committed lockfile keep the four teammates on one toolchain. Native macOS/Windows targets are not included: both contributor systems can use the browser and Android; iOS needs macOS.

On this Mac:

```sh
cd /Users/prithvirajgokule/Development/Projects/Varasa/apps/varasa
/Users/prithvirajgokule/Development/flutter/bin/flutter pub get
/Users/prithvirajgokule/Development/flutter/bin/flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7357 --dart-define=APP_MODE=demo
```

Open **http://127.0.0.1:7357** in Safari, Chrome or Edge. This method works without Chrome installed. Leave the terminal running. Ctrl+C stops it. If another preview owns 7357, choose 7358. To see later source changes, restart this command and refresh the page; web-server mode has limited debugging compared with Chrome.

On another machine, clone the repository and use its local path and `flutter` on PATH. PowerShell:

```powershell
cd C:\dev\Varasa
.\scripts\bootstrap.ps1
cd apps\varasa
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7357 --dart-define=APP_MODE=demo
```

macOS/Linux bootstrap: `./scripts/bootstrap.sh`. These scripts check the SDK pin and resolve Dart dependencies. If PowerShell blocks scripts, run `flutter --version` and `flutter pub get` in `apps/varasa` directly; no machine-wide execution-policy change is needed.

With Chrome installed, `flutter run -d chrome --dart-define=APP_MODE=demo` opens it with Flutter debugging support.

## What to try

1. **Community:** inspect the supplied Warli/game artwork; like a story and open Discuss. The feed uses “Load more” and pull-to-refresh. Story cards listen for updates.
2. **Contribute:** publish a memory with optional photo/PDF and place. Expand the pin section to choose coordinates on a map. Publishing returns to the refreshed feed.
3. **Find people:** search `meera` or `arjun`, follow a profile, then use Following.
4. **Profile:** edit your name/bio/avatar. Expand Community & account and open Friend requests and accept Arjun's sample request. Following and friendship are separate relationships.
5. **Report/block:** use the story/member menus; unblock from Profile → Blocked members. In demo only, Profile exposes a sample moderation queue.
6. **Your account & data:** prepare an export, open Files, and download its JSON. Demo account deletion removes the local user's records and signs out. Reload resets the complete sample dataset.
7. **Places:** use the floating map button on Home to browse map/list views and load additional stories. Map tiles require internet; coordinates and the list remain usable if tiles fail.
8. **Heritage/Games:** inspect the preserved articles and game discovery screen. Challas Aath remains unavailable until its Unity source is recovered.

Demo edits are memory-only, not synced between teammates. Demo PDF attachments are not hosted links. Use the backend below to test real uploads and accounts.

## Local Firebase backend — no live project required

Additional tools: **Node 22**, **Java 21**, and npm. Root `package-lock.json` pins Firebase CLI 15.33.0; use the workspace commands, not an older global CLI. `functions/package-lock.json` pins the backend dependencies. All commands start at the repository root unless stated otherwise.

```sh
node --version
java -version
npm ci
npm ci --prefix functions
npm run emulators
```

This starts Auth 9099, Firestore 8080, Storage 9199 and Functions 5001 against **demo-varasa**. Use a free terminal and keep it running. The local Emulator UI address is printed by Firebase. Do not connect this config to a live project.

In terminal two, run the app:

```sh
cd apps/varasa
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7358 --dart-define-from-file=config.emulator.example.json
```

Open **http://127.0.0.1:7358** and create an email/password test account. Open an incognito/private window for a second account. Google OAuth is intentionally unavailable in emulator mode. There is no preloaded remote demo dataset.

In terminal three, advance export/deletion and fan-out queues:

```sh
npm run workers:local --prefix functions
```

Scheduled functions do not tick automatically in the Emulator Suite. The local worker safely hardcodes loopback service endpoints and requires a `demo-` project. It processes pending jobs every five seconds. Stop it with Ctrl+C. Retention sweeps are not automatically run by this local worker; integration tests exercise cleanup separately where stated.

AppCheck enforcement is disabled only in emulator Functions. The app requires a `demo-` project whenever emulators are enabled, disables Firestore disk persistence, and shows a Local control in the header. All four services must be running. Data disappears when emulators stop unless you deliberately use CLI import/export; do not put private exports in Git.

For Android emulator development use `--dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2`. Android debug builds allow local HTTP. Physical devices require intentional LAN binding/firewall setup; never expose emulators publicly. iOS simulator HTTP networking and native plugin setup still require device validation.

## Run the checks

From `apps/varasa`:

```sh
flutter analyze
flutter test
flutter build web --dart-define=APP_MODE=demo
```

This is a JavaScript web build. Wasm is not a supported target with the retained plugin versions.

From the repository root, with Node 22 and Java 21:

```sh
npm run test:backend
```

Use `python` on Windows if that is how Python 3 is installed. Backend tests start/stop isolated emulators and refuse non-loopback service hosts. Stop any manually running emulators first to avoid port conflicts. See [VALIDATION](VALIDATION.md) for actual results and gaps. CI supports macOS/Windows Flutter checks and a Linux emulator suite after a GitHub remote is configured.

## Connected development project

No project, billing plan, credentials or deployment has been created for you. Use a separate development project before considering legacy cutover.

1. Register the correct platform app. Enable Email/Password Auth, Firestore and Storage. Functions/schedulers/Storage may require billing; verify in your Firebase console.
2. Enable App Check with reCAPTCHA v3 for web, Play Integrity for Android and App Attest/DeviceCheck for iOS. Register development debug tokens where needed. Production callables enforce App Check; Firestore/Storage App Check enforcement is a separate console setting to enable after rollout validation.
3. Copy `apps/varasa/config.example.json` to ignored `config.local.json`. Fill the registered app values and `APP_CHECK_WEB_SITE_KEY` for web. Config values are client-visible: never include Admin SDK credentials. Default Functions region is `us-central1`; change both `functions/.env` and `FIREBASE_FUNCTIONS_REGION` together if choosing another region.
4. Review rules, indexes, [release runbook](RELEASE.md) and emulator results. Authenticate your CLI deliberately to the intended account/project. When you are ready to deploy, the command is:

```sh
npx firebase deploy --project YOUR_DEV_PROJECT --only functions,firestore:rules,firestore:indexes,storage
```

5. Wait for indexes, then run `flutter run -d chrome --dart-define-from-file=config.local.json` from `apps/varasa`. Add your local host to Auth authorized domains and configure your web App Check domain.

Do not deploy v2 rules over the legacy app: its `users`/`posts` access will be denied. Consult [MIGRATION](MIGRATION.md) before cutover.

### Native configuration

Android prototype ID: `com.example.varasa_app`, minimum SDK 23. iOS prototype ID: `com.example.varasa`, minimum iOS 13. Register these or coordinate ID changes across the project and Firebase. Native desktop targets are not supplied.

Android: install Android Studio/SDK and review `flutter doctor --android-licenses` yourself. Use the Android app's Firebase values in ignored `config.local.android.json`. For Google sign-in, register each teammate's SHA-1/SHA-256 debug fingerprints and set `GOOGLE_SERVER_CLIENT_ID` to the OAuth web client ID. Explicit Dart initialization does not require checked-in google-services.json. App Check/Google device setup still needs native validation.

iOS: install full Xcode and CocoaPods, select Xcode's developer directory and finish its first-launch setup. Use ignored `config.local.ios.json` with the iOS app ID, bundle ID and client ID. For Google sign-in copy `ios/Flutter/Local.example.xcconfig` to `Local.xcconfig` and fill `GOOGLE_REVERSED_CLIENT_ID`. The demo fallback URL scheme is not OAuth configuration. Commit a verified Podfile.lock once pods are resolved; keep local signing settings private.

```sh
flutter devices
flutter run -d YOUR_DEVICE_ID --dart-define=APP_MODE=demo
```

Android debug APK and JavaScript web builds succeeded on this Mac on 11 October 2026. ADB found no connected phone, so installation and native interaction remain unverified. iOS still requires full Xcode/CocoaPods setup. Browser serving through Safari is available.

## Troubleshooting

- **Wrong app:** open `apps/varasa`, not `varasaapp` or a historical checkout.
- **Dependency differences:** compare SDK pin and committed locks; use `pub get`/`npm ci`, not uncontrolled upgrades.
- **Emulator functions.config error:** use the root pinned CLI via `npm run emulators`, not the old global Firebase CLI.
- **Unavailable callable:** start/deploy Functions in the same region as the app.
- **Missing index:** deploy the checked-in indexes and wait for readiness; emulators do not prove production index availability.
- **Export stuck locally:** run the separate local queue worker; see failed-job recovery in RELEASE.
- **Permission denied:** check identity, blocks/suspension, project, rules and App Check. Do not make rules public to bypass it.
- **Port in use:** stop the earlier session or choose a new web port. Do not kill unrelated processes.

Official references: [Flutter web setup](https://docs.flutter.dev/platform-integration/web/setup), [Firebase callable services](https://firebase.google.com/docs/functions/callable), [App Check for Flutter](https://firebase.google.com/docs/app-check/flutter/default-providers), [OpenStreetMap tile policy](https://operations.osmfoundation.org/policies/tiles/).

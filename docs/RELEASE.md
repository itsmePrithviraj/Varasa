# Release and operations runbook

No release or remote backend deployment has been performed. Start with SETUP.md and VALIDATION.md. Do not cut over the original app without a reviewed MIGRATION.md plan and verified backup.

## Android preview

A debug APK is for device review, not a store release. Enable Developer options and USB debugging on your Android phone, connect a data-capable cable, unlock it and accept its USB debugging prompt. From `apps/varasa`:

```sh
flutter devices
flutter run -d YOUR_ANDROID_DEVICE_ID --dart-define=APP_MODE=demo
# Or produce an APK to install manually:
flutter build apk --debug --dart-define=APP_MODE=demo
```

APK output: `apps/varasa/build/app/outputs/flutter-apk/app-debug.apk`. Run builds on the computer; Flutter installs and runs the app on the phone. If the device is absent, check USB data mode/cable and Android platform-tools; Windows may need the manufacturer's USB driver. If unauthorized, unlock the phone and approve its prompt. Review any SDK license prompt yourself with `flutter doctor --android-licenses`.

## Signed release

Choose final Android/iOS identifiers and register matching Firebase apps. Copy `apps/varasa/android/key.properties.example` to ignored `key.properties`, supply a private signing key and store credentials securely. Release builds intentionally fail without these values. Never commit keys, credentials or service accounts. Configure iOS signing through Xcode on macOS.

After connected-device checks, build with the platform's ignored configuration, for example `flutter build appbundle --dart-define-from-file=config.local.android.json`. The production project must already have correct services, indexes, providers and App Check rollout.

## Backend operations

Use Node 22 and the workspace Firebase CLI. Confirm selected development project before deployment; SETUP.md contains the explicit deploy command. Validate indexes and all schedules, moderator custom claims, failure/retry logs and budget alerts. Grant moderator roles only through trusted admin tooling after verifying the account ID. Review `functions/scripts/admin.mjs` usage before executing mutations.

Run the local queue worker separately in emulators. Review failed account/export/fan-out jobs and retry through supported interfaces after correcting the underlying cause. Export parts expire after seven days. Storage retention must allow in-flight uploads and authorized references; never run global deletion from the app. Avoid logging private export content.

Public release also needs artwork permissions, cultural source review, privacy/store declarations, support contacts, accessibility/device testing and a rollback plan. A passing emulator suite is not a deployment approval.

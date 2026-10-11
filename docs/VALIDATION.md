# Validation evidence — 11 October 2026

Canonical app: `apps/varasa`. Flutter 3.35.1 / Dart 3.9.0 on macOS. Backend tests used Node 22, Java 21 and workspace Firebase CLI 15.33.0 with the isolated `demo-varasa` project. No remote deployment or real-data migration was performed.

| Check | Result | Scope |
| --- | --- | --- |
| `flutter analyze --no-pub` | Passed, no issues | Final restoration source and tests |
| `flutter test --no-pub --dart-define=CAPTURE_UI=true --reporter expanded` | 9 passed | 6 repository cases, 2 interaction/layout cases, 1 multi-screen restoration case |
| `npm run test:backend` under Node 22 | 10 passed | Isolated Auth/Firestore/Storage/Functions emulators; shut down after tests |
| `flutter build web --no-pub --dart-define=APP_MODE=demo` | Passed | JavaScript release build at `apps/varasa/build/web` |
| `flutter build apk --debug --no-pub --dart-define=APP_MODE=demo` | Passed | Final debug APK at `apps/varasa/build/app/outputs/flutter-apk/app-debug.apk` |
| `adb devices -l` | No devices listed | No physical-phone installation or interaction verified |
| Original-source SHA-256 comparison | 103 files matched, 0 changed | All source files recorded across five historical copies in source-inventory.json |

## Coverage and fixes

Repository checks cover cursor pagination after deletion, idempotent likes/follows, block visibility, friend transitions, unique handles, comment cursors, moderation/export/deletion and input validation. The phone interaction flow publishes, accepts a friend and prepares an export. Layout checks cover wide rail/short-window fallback and five restored tabs at 320×640 with 160% text; login is also exercised at 320×500.

Backend cases cover atomic handle reservation, social retry behavior, reciprocal blocking, callable/rules authorization, moderation, export, retention, storage ownership/type/overwrite and resumable deletion. A storage overwrite test initially failed. Adding an explicit `resource == null` guard to create rules corrected it; the complete 10-case suite then passed. These checks are targeted, not an exhaustive security or concurrency audit.

The demo job stream and feed-card identity fixes passed the interaction flow. The renderer capture harness waits for image decoding and loads actual fonts; incomplete early captures were replaced before review.

## Rendered evidence

Actual Flutter renderer captures, not physical-device screenshots:

- `.impeccable/review/phone-home.png`
- `.impeccable/review/phone-games.png`
- `.impeccable/review/phone-heritage.png`
- `.impeccable/review/phone-profile.png`
- `.impeccable/review/phone-login.png`
- `.impeccable/review/desktop-home.png`

Phone captures are 390×844, desktop 1200×900. They were compared with the five user references in `.impeccable/references/`. Independent review confirmed the restored silhouettes/composition and requested profile hierarchy, map error layering and documentation corrections. Review status is recorded in WORK_LOG.md.

To regenerate captures from `apps/varasa`, set `FLUTTER_ROOT` to your pinned Flutter SDK (required for real Roboto/MaterialIcons fonts):

```sh
FLUTTER_ROOT=/path/to/flutter flutter test --dart-define=CAPTURE_UI=true test/ui_restoration_test.dart --reporter expanded
```

Plain `flutter test` runs behavior checks without writing captures or requiring FLUTTER_ROOT.

## Limits and build note

Live map tiles, physical Android, native share/file dialogs, keyboard/TalkBack, connected OAuth/App Check, clean Windows setup and iOS have not been validated in this pass. Demo login is intentionally a local entry rather than real authentication. Unity runtime is absent by owner direction.

Retained plugins do not support Wasm. The pinned SDK's normal JavaScript build succeeds with Wasm dry-run warnings. A `--no-wasm-dry-run` attempt failed because this SDK still constructed a Wasm target with dryRun disabled; use the successful plain build command above. No SDK/plugin upgrade was made to silence these warnings.

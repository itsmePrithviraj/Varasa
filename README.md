# Varasa

Share living traditions, explore cultural stories, and rediscover folk games. This rebuild preserves the original artwork, heritage palette, bundled heritage lettering and Challas Aath vision.

**The active app is `apps/varasa`.** Historical copies—including `varasaapp/`—are preserved and excluded from this repository.

[Run and explore](docs/SETUP.md) · [Task board](TASKS.md) · [Resume work](CONTINUE_HERE.md) · [Progress log](docs/WORK_LOG.md) · [Team Git workflow](docs/COLLABORATION.md) · [Validation results](docs/VALIDATION.md)

## Original UI restoration

The current screens reuse the original shaped headers, curved navigation, floral login, arch game cards, cultural category artwork and profile ornament. The consolidated backend remains in place. [Restoration notes](docs/UI_RESTORATION.md) · [Android USB instructions](docs/RELEASE.md#android-preview)

## See the app

Use **Flutter 3.35.1 / Dart 3.9.0**. From this repository:

```sh
cd apps/varasa
flutter pub get
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7357 --dart-define=APP_MODE=demo
```

Open **http://127.0.0.1:7357** in your browser. Keep the terminal running; Ctrl+C stops it. If the port is already in use, use `7358` in both places. With Chrome installed, `flutter run -d chrome --dart-define=APP_MODE=demo` also works.

The demo needs no Firebase credentials. It includes sample stories, profile editing, contributions, likes/discussions, follows, friend requests, blocking/reporting, moderation and data export. Changes reset on reload. Maps require an internet connection. Unity gameplay remains deferred because its source is on another computer.

For real shared or persistent data, use the **four-service Firebase emulator** or an isolated development project, following [SETUP](docs/SETUP.md). The app never silently falls back to the demo.

## Repository

```text
apps/varasa/     Flutter app, Android/iOS/web targets, assets, tests, lockfile
functions/       Node 22 trusted social services, moderation and maintenance jobs
firebase/        V2 Firestore/Storage rules and indexes
scripts/         Cross-platform bootstrap and offline migration planner
games/           Deferred Unity integration contract
docs/            Setup, architecture, migration, release, validation and work log
```

The latest implementation uses normalized relationships, unique handles, cursor feeds/comments, server-managed counters and resumable account jobs. See [ARCHITECTURE](docs/ARCHITECTURE.md) for its boundaries and [KNOWN_ISSUES](docs/KNOWN_ISSUES.md) for remaining release work. No remote backend has been deployed or old database migrated.

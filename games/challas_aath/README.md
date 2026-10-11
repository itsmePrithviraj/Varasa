# Challas Aath — reserved integration boundary

The original Unity source is on another computer. The owner confirmed it should be left unintegrated during this pass. **This directory contains no game implementation or exported runtime.** The existing Flutter game screen preserves its imagery and cultural story and clearly marks play unavailable.

## When the source returns

Bring the Unity project's authored `Assets/` (with `.meta`), `Packages/`, and `ProjectSettings/`, including the exact editor version. Do not copy `Library`, `Temp`, `Obj`, generated exports or just an APK. A built APK cannot substitute for the source needed for a supported embedded integration.

Before choosing an adapter, establish the actual implemented regional rules: board layout, tokens per player, shell/die scoring, safe squares, capture requirements, bonus turns and winning condition. Existing copies contain inconsistent rule descriptions; do not silently invent a replacement game.

The intended path is Unity as a Library in the Flutter mobile host, with a fullscreen game experience and a reliable return to Varasa. Flutter owns authentication and community data; Unity owns gameplay. Export/build outputs are generated per platform, not handed around as two consumer installers.

## Proposed bridge v1 (Dart contract exists; native handlers do not)

Channel: `varasa/games/v1`

| Method | Arguments | Result |
| --- | --- | --- |
| `isAvailable` | `{ "gameId": "challas_aath", "protocolVersion": 1 }` | bool, true only after the native host/runtime is installed and compatible |
| `launch` | same | completes when the host returns, or a PlatformException on failure |

The Flutter gateway treats absent handlers, unsupported platforms and failed probes as unavailable. No Firebase token, password or admin credential crosses this boundary. Do not accept a client-reported score as a trusted leaderboard result.

Future work: native Android/iOS host adapters, export automation, Unity lifecycle/return handling, pause/resume/audio/orientation behavior, state preservation, version compatibility, crash recovery and actual device validation. Web gameplay requires a separate deliberate WebGL strategy; it is not enabled here.

Unity documents platform-specific integration and fullscreen limitations in [Unity as a Library](https://docs.unity.com/en-us/engine/6000.3/manual/platform-specific/cross-platform-features/unityasa-library). Check the documentation for the recovered project's editor version before implementation.

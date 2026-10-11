# Known issues and release boundaries

Updated 11 October 2026. See VALIDATION.md for checks actually run.

- **Unity deferred:** original game source/runtime is on another PC. Game discovery and information work; the game itself is not playable here.
- **Physical devices:** restored layouts have Flutter-renderer coverage, not physical-phone approval. Keyboard, TalkBack/VoiceOver, file picker/share sheet and native OAuth still require device checks. Hosted Windows/macOS web builds and tests now pass. Windows Android development and iOS remain unverified.
- **Connected backend:** trusted v2 services/rules exist and local emulators are exercised. No remote deployment, indexes, scheduled jobs, billing, App Check rollout or OAuth credentials have been configured. Emulator results do not establish production readiness or exhaustive race/security coverage.
- **Legacy cutover:** v2 uses profiles/stories and normalized edges; original users/posts are not automatically migrated. Deploying v2 rules over the original app would break its access. Review migration output, private fields and backups first.
- **Demo:** sample changes reset on restart. No real account/sign-in is needed. Demo PDF attachments are not hosted downloads. Profiles/content are samples.
- **Map:** internet required for OSM tiles; list alternative remains available. Places are derived from loaded stories; load more for further results. No automatic location permission or cultural-landmark database is implied. Review tile provider capacity/terms before public scale.
- **Account jobs:** local scheduled functions need the separate local worker; production requires deployed scheduling. Retention/export cleanup and failed jobs require operational monitoring.
- **Release:** prototype bundle IDs remain. Android release requires private signing configuration and refuses missing keys. No store publication has occurred.
- **Content/assets:** original student-project descriptions and raster artwork are retained. Cultural facts/regional variants and image rights need editorial/owner review. Added fonts include OFL licenses.
- **Dependencies:** Flutter 3.35.1 with compatible retained plugin majors. Web is JavaScript, not Wasm. Native desktop release targets are not included.
- **Git/team setup:** published at https://github.com/itsmePrithviraj/Varasa. First hosted Mac/Windows/backend CI passed; collaborator invitations and main protection remain to be configured. Teammates need the pinned SDK and their own ignored local configuration.

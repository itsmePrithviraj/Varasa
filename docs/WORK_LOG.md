# Work log

## 10 October 2026 — consolidation and implementation

**Request:** compare all copies without assuming a primary one; consolidate under `Development/Projects/Varasa`; improve architecture, collaboration and experience while preserving the original cultural/social/game identity; leave a clear log and commands; do not test.

**Owner clarification:** Unity source is on another computer. Leave the game unintegrated for now.

### Completed implementation

- Compared five Flutter copies by Git history, source files, modification times, feature presence and source hashes. Identified `varasa_old` as the broadest reference, not a certified latest release. Logged an unresolved merge in `varasa_app` without altering it.
- Created `apps/varasa` as the canonical Flutter project. Preserved all historical folders and their Git state. The old `varasaapp/` in the target folder is excluded from the new repository.
- Retained original art, logo, cultural collection and fonts. Reimplemented UI using an explicit theme, shared components and feature folders; removed duplicate commented implementations from the active app.
- Split data access from widgets through `VarasaRepository`, Firebase implementation and functional in-memory demo.
- Added explicit startup modes, recoverable configuration failure, authentication gate, profile initialization and sign-out route clearing.
- Added email sign-in/sign-up, password reset and web/native Google sign-in code paths. Native OAuth still requires platform configuration.
- Implemented community feed, following filter, likes, comments, text sharing, people search, own/other profiles, profile text editing and membership lists.
- Implemented cross-platform byte-based photo/PDF selection, text-only posts, input validation, optional place/coordinates, failed-upload cleanup and author-only post removal.
- Added searchable cultural collection/detail screens and a location-based story list with external Maps links.
- Preserved Forgotten Gems/Challas Aath imagery and concept; replaced a no-op Play button with explicit availability. Defined a future native bridge without adding a fake runtime.
- Added retained tab navigation and a wide-window rail with a short-window/text-scale fallback. Inputs, actions, progress and errors have visible labels/states.
- Corrected font registration under Flutter, removed Google Fonts network fetches, removed bundled `.env`, copied credential/config files and the hardcoded native Maps key from the new app. Removed unnecessary location/storage/camera permissions.
- Kept Flutter 3.35.1/Dart 3.9.0 and refreshed the dependency lockfile. Removed unused plugin families; no broad package-major upgrade.
- Restored iOS Podfile/xcconfig setup, set Android minSdk 23, lowered excessive Gradle memory defaults, retained platform IDs, and ensured the Gradle wrapper is not ignored by Git.
- Added Firestore/Storage rule source, index configuration, setup/config examples, cross-platform bootstrap scripts, editor launch entries, line-ending policy, PR template and manual-only validation workflow. Rules have not been deployed.
- Added architecture, migration, collaboration, manual checks, known issues, source inventory, product/design documentation and Unity handoff.
- Initialized a local Git repository on `main`. No initial commit, remote, push, GitHub project, cloud deployment or old-data migration was performed.

### Source-review corrections

- New profile handles lowercase UID fragments so they comply with the rules.
- Coordinates are validated even if the optional form section is collapsed.
- Comment input locks during submission and only clears while mounted.
- Both repositories display the latest 100 comments chronologically, so recent submissions remain visible.
- Navigation rail is used only when both width and available height/text scale allow it.
- A separate source-only review scored its three reported interaction findings resolved. This is not a compiled, visual or end-to-end acceptance result.

### Commands actually executed

- Read-only filesystem/Git inspection of originals, source comparisons and hashes.
- Impeccable context loading and reading design guidance; source-only finish/documentation handoffs.
- File creation/copying and local Git initialization for the new project.
- `flutter pub get` in `apps/varasa`: **completed successfully**, lockfile updated. Package resolution is not compilation.
- Dart formatter on new source: completed. Its initial lint-include resolution warning occurred before package resolution; it did not represent an analyzer run.
- Source inspection of import/asset references, local configuration exclusions and written files.

### Explicitly not run

No `flutter test`, `flutter analyze`, build, app launch, emulator, simulator, browser rendering, rules evaluation or deployment. No claim is made that cross-platform compilation or runtime behavior has passed. The owner requested to perform validation later.

### Follow-up order

1. Run the local demo in Chrome on Mac and Windows using SETUP.md; log results in MANUAL_CHECKLIST.md.
2. Resolve analyzer/build findings with the pinned toolchain before adding features.
3. Configure an isolated Firebase development project and evaluate rules with two accounts.
4. Review legacy data and intended feature parity before migration.
5. Restore optional features (avatar uploads, embedded maps, relationship model) according to the product decision.
6. Integrate the real Unity source only when the owner brings it back.
7. Complete moderation, privacy/account deletion, cleanup jobs, scalable queries and signing before a public release.

## Continuation batch — 10 October 2026

The owner requested ongoing progress/task logging to survive usage exhaustion, then explicitly asked to continue. Added `CONTINUE_HERE.md` and `TASKS.md` as durable session entry points. Current next task: explicit opt-in Firebase emulator wiring; no emulator will be launched. Existing no-testing and deferred-Unity instructions remain active.

### Completed: explicit emulator wiring

Added opt-in USE_FIREBASE_EMULATORS and host configuration, a demo-project guard, all-three-service emulator initialization before repository construction, disabled emulator Firestore disk persistence, and a persistent local-backend banner. Added `config.emulator.example.json` and exact owner-run commands in SETUP. No emulator or application was executed. Next task: custom avatar uploads.

### Completed: custom avatar editing

Added shared byte-based file selection, 3 MB image-only profile uploads, preview/removal/save UI, repository-side validation and cleanup when profile writes fail. Versioned avatar objects are tracked with avatarPath; prior versions remain until a trusted retention pass because historical posts may reference them. Added own-path avatar Storage rules and public-profile path validation. Avatar display now handles local demo bytes and explicit Storage-emulator URLs. Source only; no upload or rules evaluation was run.

### Completed: bounded feed windows and live story detail

Added PostWindow with one-record lookahead, explicit hasMore, a 300-record ceiling and shared loading/end-of-window footer. Both feed and profile stop requesting unbounded live histories; following remains explicitly a filter of the loaded window. Added watchPost to both repositories and rebuilt detail around a live post stream, including unavailable state after deletion, current likes/attachments and retry. No app/query execution was performed. Next: source-only review, formatting and handoff updates.

### Source-only handoff for continuation batch

A bounded independent source review found no material mismatches in emulator configuration, avatar/repository/rule contracts, bounded windows or live-detail call sites. This is not a compile, runtime or security-rule result. DESIGN.md and its sidecar were updated from source only. An additional source safeguard supplies a valid local iOS URL-scheme fallback and rejects missing native OAuth IDs before invoking the plugin; emulator Google OAuth is explicitly unavailable in favor of local email accounts.

Updated SETUP, ARCHITECTURE, MIGRATION, KNOWN_ISSUES and MANUAL_CHECKLIST to reflect implemented avatar editing, emulator wiring, 300-record history ceiling and live detail. Ran Dart formatting on the new source, without invoking the analyzer or app. No additional packages, tests, builds, launches or deployments were needed in this continuation batch.

### Checkpoint saved

All five continuation-batch source tasks are marked complete in TASKS.md. CONTINUE_HERE.md now points to owner-run validation and preserves all deferred work and constraints. Local changes remain uncommitted; no remote exists. Historical copies remain untouched.

## Completion pass — 10 October 2026

Owner explicitly requested continuing the remaining task board to completion. Implementing remaining locally actionable features instead of treating the earlier source batch as the end. Scope now includes normalized social schema, trusted backend services, cursor feeds, friends, moderation, privacy jobs and embedded map UI. No runtime tests or deployments authorized. Schema v2 will use separate collections from legacy data; no old database is being changed.

### Schema/backend implementation checkpoint

Added trusted callable backend modules for normalized relationships, unique handles, cursor feeds/comments, friends, reports/moderation, and account jobs. Added durable fan-out and maintenance work queues plus bounded scheduled storage cleanup. Flutter Firebase repository now targets separate v2 `profiles`/`stories` collections and invokes trusted mutations; demo implementations are being expanded to the same interface. Backend package-lock was resolved without running install scripts; host Node is 26 while deployment is pinned to Node 22, so runtime remains unverified. No code was deployed or executed.

### Testing authorization — 10 October 2026

Owner explicitly asked to continue implementation, then test and explain how to run it. This supersedes the earlier no-testing restriction. Local analyzer, automated tests, demo build/launch and isolated emulators are now in scope; remote deployment and real-data migration remain excluded. Resuming from unfinished account/map screens and v2 rules.

### Connected completion features

Added account export/deletion screens, paged discussions with report/remove controls, embedded attributed maps and optional pin selection. Replaced legacy Firebase rules with deny-by-default v2 rules and indexes. Added Android release signing guard, offline migration planner, explicit guarded import/admin tools, and a local queue worker because emulator schedulers do not tick automatically. Historical source hashes still match the original inventory. Flutter analyzer initially found only lint findings; corrections and new repository/widget/emulator tests are now running.

### Owner paused for mobile instructions / preservation review

Web release build and Safari rendering succeeded. Nine isolated backend tests passed with the newly pinned Firebase CLI. Six demo repository tests passed; the phone widget workflow found and led to a keyed-feed fix, then exposed AccountPage jobs-stream resubscription. That failure is still open. Source reviewer identified four UX issues; corrections were written but not yet validated. Native compilation is unverified and host Android/iOS prerequisites are incomplete. See the latest CONTINUE_HERE checkpoint for exact remaining steps. Owner's question takes priority over ongoing edits/tests.

### Android device connection and Kotlin DSL build fix

- Connected device ONEPLUS A6010 (`547d48a0`) authorized via USB debugging.
- Fixed Kotlin DSL syntax error in `apps/varasa/android/app/build.gradle.kts`: corrected `minSdkVersion flutter.minSdkVersion` to `minSdk = flutter.minSdkVersion`.


## UI correction — 11 October 2026

Owner supplied original screenshots and rejected the generic layout of the rebuild. Saved references, inspected legacy screens and actual PNG shapes, and started restoring the original compositions over the current repository boundary. No further visual reinterpretation is authorized beyond small usability/accessibility fixes.

## 11 October 2026 — original UI restoration implementation
- Restored original PNG header silhouettes, curved icon navigation, cream feed cards, arch game carousel, floral login, category banners and ornamental profile in canonical app. Historical copies remain read-only.
- Floating home map button opens map with parchment overlay controls and selectable story previews; list fallback retained.
- Restored Itim/Cormorant typefaces with local fonts and OFL licenses; kept Cinzel. Preserved existing repository/backend contracts and social/account actions.
- Flutter analysis passed after implementation. UI/interaction tests and valid rendered captures are in progress; do not claim native-device verification yet.
- Added `test/ui_restoration_test.dart`; capture mode requires FLUTTER_ROOT and CAPTURE_UI=true. First captures were incomplete (images/fonts loading), so they are not review evidence until regenerated.

## 11 October 2026 — restored UI validation and build completion
- Valid Flutter-rendered captures now show original home/scalloped headers, curved navigation, cream cards, ornate login, arch carousel, illustrated category rows and ornamental profile.
- Independent Impeccable review requested Posts above Followers/Following, visible map tile-failure feedback below overlay controls, and corrected durable design docs. Profile/count hierarchy and map feedback position were fixed; Friends remains under Community & account. Final documentation review pending at this entry.
- All 9 Flutter tests passed, including demo publish/friend/export flow and 320px/160% text layouts; analyzer reported no issues.
- All 10 backend emulator cases passed after tightening Storage create rules with resource == null to prevent overwrite. No remote data touched.
- Final JavaScript web build and Android debug APK succeeded. ADB lists no connected phone; no device installation/runtime approval claimed. Wasm is unsupported; see VALIDATION.md for the pinned-SDK flag caveat.
- All 103 recorded original source hashes still match. Original folders were not modified.
- Replaced stale task/checkpoint/known-issues/manual-checklist text; added release and validation runbooks. Durable visual authority remains the five saved user screenshots, not the rejected intermediate design.

## 11 October 2026 — restoration handoff closed
- DESIGN.md and .impeccable/design.json now reflect the restored implementation; sidecar JSON validates. All referenced runbook links resolve. Dart format check passed without changes.
- Independent final verdict: **ship**, scoped to three corrections — profile hierarchy resolved, map error layering resolved in source scope, durable docs resolved. This is not whole-surface accessibility/native certification.
- UI restoration tasks are complete for this pass. Next: owner checks debug APK on physical Android against original screenshots. ADB had no phone attached. Unity, native OAuth/live map/provider behavior, clean Windows and iOS remain external/device follow-up.
- Canonical app, APK location, exact commands, nine Flutter/ten backend test results and limitations are in docs/VALIDATION.md and docs/RELEASE.md. Resume from CONTINUE_HERE.md.

## 11 October 2026 — first Git/GitHub publication preparation
- Owner requested Git/GitHub setup and selected a new public repository named Varasa. Confirmed `varasaapp/` is the historical copy and is excluded by the root ignore rule; it remains untouched on disk.
- Installed GitHub CLI; started browser device authentication. Existing Git author configuration retained.
- Reviewed 247 candidate files (~12.29 MiB before these notes): no files over 50 MiB, no historical-folder candidates and no matches for common credential/private-key patterns. Build outputs, dependency caches, local config/signing files and APKs are ignored. Also excluded IDE .iml files and redundant source font ZIP.
- Updated collaboration guide and CI triggers. Flutter checks now run on macOS/Windows; isolated Node22/Java21 backend checks run on Ubuntu. Hosted results are pending publication.

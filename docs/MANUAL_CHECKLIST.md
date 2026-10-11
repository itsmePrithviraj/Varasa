# Device and release validation checklist

Local automated results are recorded in VALIDATION.md. This checklist covers remaining manual/device work, not a claim that everything is untested.

## Original UI on Android

- [ ] Connect the phone and run the demo using RELEASE.md's USB instructions.
- [ ] Compare home/header/navigation, floral login, game arches, profile and heritage rows with `.impeccable/references/`.
- [ ] Use the floating map button, tap a pin, close/reopen its preview and switch to list view. Test loss of tile connectivity; error message must remain below controls.
- [ ] Check small screen, rotation, 200% text, keyboard and Android gesture/navigation insets.
- [ ] Check TalkBack labels, focus and the icon-only navigation; tab through the web version.
- [ ] Visit your profile after creating posts; Posts reflects loaded results until pagination is exhausted. Friends remains in Community & account.
- [ ] Confirm Challas Aath says Coming soon, with its cultural description accessible.

## Social, files and accounts

- [ ] Publish text/photo/PDF; cancel selection, reject unsupported/oversized files, try optional coordinates and open keyboard.
- [ ] Like/comment, open story detail, follow/unfollow and accept/cancel friend requests; preserve drafts across tabs.
- [ ] Edit/remove avatar; check native picking and share sheet, long names and captions.
- [ ] Block/unblock and report; review moderation with an intentionally assigned moderator account.
- [ ] Export files using the native save dialog; test repeated taps/cancel. Test deletion only on disposable accounts.
- [ ] Sign out from nested routes and verify private routes clear.

## Isolated connected backend

- [ ] Follow SETUP.md with two disposable accounts; real uploads and shared data survive restart.
- [ ] Validate Email/Password, password reset and separately configured Google OAuth on each platform.
- [ ] Confirm production indexes, App Check and scheduled queue/retention workers before public use.
- [ ] Verify failed upload/job/network recovery and expected unauthenticated/other-user denial.
- [ ] Validate large cursor pages/comments and concurrent mutations under realistic volume.
- [ ] Review legacy private fields before migration; never deploy v2 rules blindly over the original app.

## Team/release

- [ ] Fresh macOS and Windows clone with pinned Flutter3.35.1 and lockfiles, no borrowed caches.
- [ ] Physical Android approval; iOS build/signing/CocoaPods and device approval.
- [ ] Final IDs/signing/store/privacy metadata, asset permissions, cultural sources and rollback plan.

Record date, device/OS, app mode, scenario, result and reproduction steps in WORK_LOG.md or an issue. Debug APK success alone does not certify device behavior.

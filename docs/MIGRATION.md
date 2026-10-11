# Source comparison and migration

Comparison performed 10 October 2026. Source modification times are evidence of local file history, not proof of release order. Most directories lack useful Git history, so no single copy was assumed primary.

| Copy | Dart files | Most recent source mtime | Evidence |
| --- | ---: | --- | --- |
| `Development/Project/varsa` | 12 | 5 Oct 2025 | Earlier prototype; initial commit dated 18 Sep 2025 |
| `Development/Projects/Varasa/varasaapp` | 17 | 31 Oct 2025 | Smaller implementation; initial setup commit dated 5 Oct 2025 |
| `Development/Project/varasa` | 22 | 1 Nov 2025, 11:41 local | Broader social implementation; no Git repository |
| `Development/Project/varasa_app` | 24 | 8 Oct 2025 | Local uncommitted changes and unresolved `AA README.md` merge state |
| `Development/Project/varasa_old` | 28 | 1 Nov 2025, 12:20 local | Broadest functionality: search, other profiles, post detail and post service |

**Conclusion:** `varasa_old` is the strongest functional reference, despite its name. It cannot be certified as the last released version. The new project is a consolidation/reimplementation, not a claim that this folder was the authoritative release. Full source-file hashes are retained in `source-inventory.json`.

## What was retained

- Original cultural collection, including paintings, instruments, poetry, festivals and games.
- Supplied logo, artwork, game imagery and decorative font files/licence.
- Feed, following, profiles, search, comments, likes, contribution and location concepts.
- Android/iOS/web scaffolding from the most complete reference, cleaned of local/generated configuration.
- Existing prototype application IDs; Dart package name is now consistently `varasa`.
- Existing source copies, including their Git state, without modification.

## Intentional changes and remaining differences

| Before | Consolidated app |
| --- | --- |
| Flat screens mixing Firebase calls and rendering | Features + domain contracts + two repositories |
| Required bundled `.env` and existing Firebase project | Explicit compile-time client config; default local demo |
| Multiple Cloudinary/Firebase upload paths | One Firebase Storage path; legacy HTTPS images still render |
| Decorative icon taps and route replacement for each tab | Labeled navigation, state-preserving tabs and wide-window rail |
| Location required for posting; native Maps key | Optional place/coordinates; external Maps links |
| Empty Play action / contradictory rules copy | Explicit missing-runtime state and original cultural article |
| Multiple full blocks of commented code | New focused source files; historical copies remain available |
| Manually maintained social counters | Counts derived from membership arrays |
| Friend requests plus following | Following is the active relationship model; old friend-request records are not migrated |
| Profile photo upload UI | Cross-platform 3 MB avatar upload, preview, removal and failed-write cleanup |
| Public prototype content mixed with setup | Readable setup, migration, collaboration and validation documents |

This is not full behavior parity with every historical branch. In particular: embedded map/location picker, friend-request acceptance and playable Unity integration are not included. The inherited document-upload screen was largely commented-out; the new composer provides an actual PDF upload path in connected mode.

## Existing Firebase data

Start with a separate development project. **Do not point the rebuild at the old shared project and deploy rules without reviewing the existing data and clients.** No automatic migration or global repair runs at startup.

Before importing old records with a trusted admin tool:

1. Export/back up the old data and inventory its field types, subcollections and Storage/Cloudinary references.
2. Public `users/{uid}` may contain only public profile information. Move email, phone and private fields to an owner-only collection or keep them solely in Firebase Auth. Firestore rules cannot hide selected fields within a readable document.
3. Normalize username/username_lower to lowercase display handles; preserve UID ownership. Fill absent bio/photo and membership arrays. Resolve malformed arrays and references to missing users.
4. Reconcile following/followers as reciprocal sets; do not trust old counters. Decide separately how friends and pending friend requests should translate—do not auto-follow people without a product decision.
5. Give posts missing timestamps an agreed import timestamp, because ordered queries exclude records with no ordering field. Preserve valid original timestamps and author ownership. Skip `_init` comment sentinels when importing.
6. Inspect the old `(0, 0)` location defaults. Do not convert every such point into a real pin. Missing coordinates should be null, not zero; real `(0, 0)` remains valid if intentional.
7. Legacy `imageUrl` HTTPS values can continue to point to Cloudinary. They do not gain a Firebase `storagePath`. Deleting such a post hides the story but cannot remove a Cloudinary object; trusted cleanup is a separate operation.
8. Normalize captions, usernames, comments and URLs to the new shape and size constraints. Deploy the required index to the development project.
9. Run the checklist with two non-admin users and adversarial rule cases before deciding on a cutover.

No user account, remote data, remote repository, Git branch or existing checkout was overwritten or migrated during this pass.

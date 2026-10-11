# Architecture

Varasa combines community storytelling, cultural reading and traditional games. Flutter owns identity, social features, navigation and the library. Unity will own Challas Aath gameplay when its source is recovered. The intended mobile integration is one host app with an embedded runtime; no Unity runtime or native handler is supplied yet.

## Boundaries

```text
main / AppConfig → demo repository OR Firebase repository
app shell → feature widgets → VarasaRepository → domain models
                                  ↓
                    Firebase Auth / Storage / callables
                                  ↓
                 Node 22 services → Firestore / trusted jobs
```

Feature widgets do not access Firebase. Demo behavior implements the same contract with session-only state. Firebase mutations are trusted callables; client Firestore writes are denied. Narrow document listeners keep visible profiles, relationship controls, jobs and story cards current. Paged collections refresh explicitly rather than pretending to be continuously live histories.

The shell retains lazily created tabs in an IndexedStack. Feed items are keyed by story ID so refresh cannot reuse an old story's listener. Session changes replace the MaterialApp navigator, clearing private routes on sign-out. Profile setup errors expose retry, sign-out and account-data access, including for suspended profiles.

## V2 records

The new schema intentionally uses different collections from the old database. No legacy data was modified.

| Path | Purpose |
| --- | --- |
| `profiles/{uid}` | Public display fields, exact server-maintained follower/following/friend counts, suspension state; no email/tokens |
| `profiles/{uid}/{following,followers,friends,incoming,outgoing}/{other}` | Individual relationship records; reciprocal updates in transactions |
| `handles/{lowercaseHandle}` | Transactional unique-handle reservation |
| `accounts/{uid}` | Private deletion state |
| `accounts/{uid}/blocks/{other}` | Private block edge; enforced in both directions |
| `accounts/{uid}/feed/{storyId}` | Following-feed references, filtered again when read |
| `stories/{id}` | Text, author snapshot, optional media/place, server timestamps/counters, tombstone state |
| `stories/{id}/{likes,comments}/{id}` | Individual likes and paged comments |
| `reports/{id}` | Private report records and moderator decisions |
| `fanoutJobs`, `maintenanceJobs` | Leased, bounded, retryable fan-out/export/deletion work |
| `rateLimits`, `backendState`, `deletedAccounts` | Server-only rate buckets, sweep position and deletion markers |

Handles identify public profiles; Firebase UIDs remain identity keys. Post/comment names are historical snapshots and do not rewrite on profile edits. Legacy arrays exist only in the small in-memory demo model, never as the Firebase relationship store.

## Pagination and distribution

Community/profile/comments/people/report pages have 20 results plus a one-record lookahead. Cursors use a stable timestamp + document ID ordering (export files use ordered IDs). Deleting a boundary record does not reset pagination. Visibility filtering may yield an empty page with another cursor; Load more remains available.

Following is a materialized reference feed. Following someone backfills their latest 30 stories; future publishes create durable fan-out work in pages of 200 followers. Jobs resume every minute in deployed Functions. References are rechecked against the current follow, block and author status before returning stories. Older pre-follow history remains available on the author's profile; it is not a full retroactive following history. Feed references contain no story text. No 300-story ceiling remains.

Places loads community pages on demand and maps only loaded records with coordinates. This is not a global geographic search index. Exact pins are optional; the app never requests automatic device location. OpenStreetMap tiles are attributed and fetched on demand with application identification; no offline bulk download exists. Replace the configurable tile provider before traffic exceeds that provider's policy/capacity.

## Writes, files and privacy jobs

Callables authenticate users, check account availability, apply rate limits and enforce App Check outside emulators. Social creation transactions reread account/block state to prevent races with deletion/blocking. Blocking and relationship cleanup are atomic. Moderator claims are set only by the trusted admin tool, never by profile editing.

Uploads are immutable, versioned Storage objects. Images: JPEG/PNG/WebP; contributions may also be PDF, maximum 10 MB; avatars maximum 3 MB. Server handlers verify object ownership, metadata and download URL/token before attaching a file. MIME declarations are not content scanning. A publish retry in the same session reuses its pending ID/upload if the draft is unchanged; a restart is not a durable outbox.

An uncertain network response must not trigger immediate file deletion because the server may have committed. A trusted hourly sweeper uses a 24-hour grace period for orphaned attachments/avatars, preserves avatars referenced by live stories, and expires export files after seven days. Story deletion clears visible content immediately; old tombstones and their subcollections are purged after seven days. Copied bearer download URLs can remain usable until the underlying file is deleted; blocks restrict discovery and authenticated reads, not already downloaded/copied media.

Export requires recent authentication and creates private paged JSON files containing owner records and file references. It is not a snapshot transaction of the entire account; concurrent edits can affect different parts. Files do not bundle binary attachments. Deletion marks the account unavailable, disables/revokes Auth, removes relationships, authored contributions, likes/comments and owned Storage, redacts related reports, removes identity records, and retains a server-only deletion marker to stop stale requests recreating the profile. Administrative moderation records and minimal job/deletion markers are retained; approve a legal retention policy before public release.

Workers claim leases with nonces, save progress after bounded steps, retry idempotently, and mark repeated failures for operator recovery. The deployed scheduler drains work; the explicit local worker replaces that scheduler in emulators. This has local integration coverage, not a scale/chaos-test certification. Exports and deletion should be monitored operationally.

## Platforms and original identity

Flutter 3.35.1 / Dart 3.9.0 and dependency lockfiles are pinned. Web is the common Mac/Windows contributor target. Android/iOS platform scaffolds remain; native desktop is not included. Release signing never silently falls back to Android debug keys.

Parchment surfaces, dark brown text, original art/navigation icons and bundled CinzelDecorative retain the project's identity. Material controls provide keyboard/focus/semantic behavior. Navigation rail requires both width and usable height/text scale; short windows use bottom navigation. Original articles remain explicitly marked for editorial review.

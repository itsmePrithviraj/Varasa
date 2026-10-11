# Working together across macOS and Windows

The shared unit is one Git repository rooted at `Varasa`, not a zip of somebody's working folder. Everyone edits `apps/varasa`. Native tool installations and local configuration stay on each machine.

## GitHub setup

The repository root is `Varasa`; the current app is `apps/varasa`. The top-level `varasaapp/` is a preserved historical copy, ignored by Git and excluded from GitHub. Do not force-add it or copy it into the new app. Fresh clones will not contain that historical folder.

The owner selected a new **public** GitHub repository named **Varasa** on 11 October 2026. GitHub authentication and the publication result are recorded in CONTINUE_HERE.md. GitHub CLI authentication happens on your own computer; never paste passwords or access tokens into chat.

When setting up a different machine, sign in using `gh auth login --hostname github.com --git-protocol https --web`, then clone the repository URL. Invite the other three teammates through the repository's collaborator settings. Each member uses their own clone and credentials.

Before committing, use `git status --short` and `git diff --cached --stat`. Keep local config, SDK paths, caches, signing keys, APKs and the original folder out of the staged files. Repository ignore rules already cover these paths.

## Small branches, clear ownership

A useful initial split is community/feed, profiles/auth, heritage/contributions, and game integration/platforms. These are suggested areas, not permanently assigned people. The domain contract, pubspec, app shell, theme and Firebase rules are shared files; coordinate changes to them before starting.

```sh
git switch main
git pull --ff-only
git switch -c feature/short-description
# Make one coherent change.
git add PATHS_YOU_CHANGED
git commit -m "Describe the user-facing change"
git push -u origin feature/short-description
```

Open a pull request; another teammate reviews it. Protect `main` after the initial publication and require PRs. Do not force-push shared branches or combine unrelated formatting, dependencies and feature work in one PR.

## When two people edit the same file

Fetch the current main branch and merge it into your feature branch:

```sh
git fetch origin
git merge origin/main
```

Resolve conflicts deliberately in the affected files, keeping both intended behaviors. `git status` names the remaining conflicts. Stage each resolved file and complete the merge commit. Never resolve a conflict by replacing the whole repository with one person's folder. A conflict in `pubspec.lock` should be resolved by agreeing the pubspec changes and re-running `flutter pub get` with the pinned SDK, then reviewing the lock diff.

## Files to commit

- Dart source, local font/assets and licences, platform source, Gradle wrapper, Podfile.
- `pubspec.yaml` **and** `pubspec.lock` together.
- Firebase rules/indexes and config examples.
- Unity `Assets`, `Packages`, `ProjectSettings` and all authored `.meta` files, once available.
- Podfile.lock after the first verified iOS install.

Do not commit generated caches, SDK paths, local JSON config, signing keys, APK/IPA files, Unity Library/Temp or a whole exported Unity build. Large Unity binary source assets may later need Git LFS; agree patterns before adding them, not after the repository becomes huge.

## Automatic checks

Testing was authorized on 10 October 2026. **Validate Varasa** runs on pushes to `main`, pull requests targeting `main`, and manual workflow dispatch. macOS and Windows resolve the pinned Flutter dependencies, check formatting, analyze, run tests and build the demo web target. A separate Ubuntu job runs the isolated Firebase emulator suite under Node22 and Java21. No production Firebase secrets are needed for these demo/emulator checks.

After the first push, inspect the Actions tab. Local checks have passed (see VALIDATION.md), but hosted-run results must be checked separately. After a successful run, protect `main` with pull requests and required checks. Do not assume the local APK proves Windows/iOS/native runtime compatibility.

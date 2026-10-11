# Your Varasa Git/GitHub guide

Repository: https://github.com/itsmePrithviraj/Varasa

## What was done

1. **Git repository:** the `.git` directory in the canonical Varasa root stores local history. It is not an app folder and should not be copied between project versions.
2. **Ignore rules:** `.gitignore` excludes the historical `varasaapp/`, build outputs/APKs, dependencies, IDE metadata, local configuration and signing files. The active app `apps/varasa` is included.
3. **Staging:** `git add` selected the files for the next snapshot. Staging does not upload anything.
4. **Commit:** `803a23a` saved the consolidated app, original UI restoration, backend, assets and docs. `9ab694f` recorded the setup checkpoint. Commits are local until pushed.
5. **Remote:** `origin` points to `https://github.com/itsmePrithviraj/Varasa.git`. It is a nickname for this online repository.
6. **Push:** `git push -u origin main` uploaded the commits and linked local `main` to `origin/main`. GitHub now has the shared copy.
7. **Actions:** the first push triggered checks on macOS, Windows and Ubuntu. Check the Actions tab; a successful push does not automatically mean the tests passed.

All Git commands below start at the canonical repository root (the folder containing README.md, apps/, functions/ and .git). Flutter commands start inside apps/varasa.

## Understand the commands

| Command | Meaning |
| --- | --- |
| `git status` | Shows branch and uncommitted changes. |
| `git diff` | Shows edits not yet staged. |
| `git add path/to/file` | Selects that file’s current changes for the next commit. |
| `git diff --staged` | Reviews exactly what the commit will contain. |
| `git commit -m "Explain the change"` | Saves a local snapshot of staged changes. |
| `git push` | Uploads commits to the configured branch on GitHub. |
| `git fetch origin` | Downloads remote history without merging it into your working branch. |
| `git pull --ff-only` | Updates the branch only if Git can move it forward without a merge. |
| `git log --oneline -5` | Shows the five most recent commits. |
| `git remote -v` | Shows where fetch/push connect. |

Saving a file, committing it and pushing it are three different actions. A commit contains only staged changes. Ignoring a file does not untrack it if it was committed previously; the old app folder was never committed here.

## The four-person workflow

Start a small feature branch from updated main:

```sh
git switch main
git pull --ff-only
git switch -c feature/responsive-heritage-shapes
```

Edit the app, run the relevant checks, and review your changes:

```sh
git status
git diff
git add path/to/the/changed/file
git diff --staged
git commit -m "Make heritage header adapt to screen width"
git push -u origin feature/responsive-heritage-shapes
```

The file path above is a placeholder: select your actual changed files. On GitHub, open a **pull request** from the feature branch into main. A teammate reviews it and the checks run. Merge when the change is ready. Others then update their local main with `git pull --ff-only`.

A branch lets each person work independently. A pull request lets the team review and combine that work. Two people editing the same lines may still cause a conflict; resolve both intended changes, rather than replacing the whole folder. See COLLABORATION.md for conflict handling.

## What you should do on GitHub

- Open **Code** to inspect the uploaded structure. `apps/varasa` should be present; top-level `varasaapp` should not.
- Open **Actions** to inspect Validate Varasa. Expand any failed job to read its logs.
- Add your other three teammates through **Settings → Collaborators**, using their exact GitHub usernames. Public visibility lets people read the code; it does not let everyone push.
- After checks pass, configure a rule for `main` requiring pull requests and review/checks. Team invitations and protection rules have not been configured automatically.

## Never copy these between teammates

Do not share `.git`, `build`, `.dart_tool`, `.gradle`, `node_modules`, local SDK paths, signing keys or private config through Git. Each teammate installs Flutter3.35.1 and runs the bootstrap/setup commands. Keep the pubspec and npm lockfiles committed so dependency versions agree.

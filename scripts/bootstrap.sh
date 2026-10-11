#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Install Flutter 3.35.1 and put its bin directory on PATH. See docs/SETUP.md.' >&2
  exit 1
fi
version="$(flutter --version --machine)"
if ! echo "$version" | grep -Eq '"frameworkVersion"[[:space:]]*:[[:space:]]*"3\.35\.1"'; then
  echo 'This project pins Flutter 3.35.1. Switch SDK before resolving packages.' >&2
  exit 1
fi
cd apps/varasa
flutter pub get
echo 'Dependencies resolved. No tests or builds were run.'
echo 'Next: flutter run -d chrome --dart-define=APP_MODE=demo'

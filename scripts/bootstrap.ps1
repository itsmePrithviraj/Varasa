$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Install Flutter 3.35.1 and put its bin directory on PATH. See docs/SETUP.md.'
}
$version = flutter --version --machine | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $version.frameworkVersion -ne '3.35.1') {
  throw 'This project pins Flutter 3.35.1. Switch SDK before resolving packages.'
}
Push-Location (Join-Path $projectRoot 'apps/varasa')
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed. See docs/SETUP.md.' }
  Write-Host 'Dependencies resolved. No tests or builds were run.'
  Write-Host 'Next: flutter run -d chrome --dart-define=APP_MODE=demo'
} finally { Pop-Location }

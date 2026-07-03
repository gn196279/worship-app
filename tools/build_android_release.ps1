# Build a release APK to share with friends.
# Screenshot OCR uses on-device ML Kit (no billing). Optional GCV_API_KEY in
# secrets.json enables Vision OCR fallback for scanned PDF pages only.
#
# Usage:
#   .\tools\build_android_release.ps1
#
# Output APK:
#   build\app\outputs\flutter-apk\app-release.apk

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$secretsFile = Join-Path $root "secrets.json"
$apkPath = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
$packageName = "com.example.gilgal_telugu_worship"

if (-not (Test-Path $secretsFile)) {
    Write-Host "Missing secrets.json in project root." -ForegroundColor Red
    Write-Host "Copy secrets.json.example to secrets.json and add your GCV_API_KEY." -ForegroundColor Yellow
    exit 1
}

$secretsRaw = Get-Content $secretsFile -Raw
if ($secretsRaw -match "PASTE_YOUR_GOOGLE_VISION_API_KEY_HERE") {
    Write-Host "Edit secrets.json and replace the placeholder with your real Google Vision API key." -ForegroundColor Red
    exit 1
}

Set-Location $root
Write-Host "Building release APK (this may take a few minutes)..." -ForegroundColor Cyan
flutter build apk --release --dart-define-from-file=secrets.json

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Done! APK ready:" -ForegroundColor Green
Write-Host "  $apkPath" -ForegroundColor White
Write-Host ""
Write-Host "To install on phone, run:" -ForegroundColor Cyan
Write-Host "  .\tools\install_android_release.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Important: stop 'flutter run' first. Debug and release builds conflict." -ForegroundColor Yellow

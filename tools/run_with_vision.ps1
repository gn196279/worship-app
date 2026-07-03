# Run the app on a connected device with Google Vision OCR enabled.
#
# Usage:
#   .\tools\run_with_vision.ps1
#   .\tools\run_with_vision.ps1 -Device 192.168.1.3:46693

param(
    [string]$Device = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$secretsFile = Join-Path $root "secrets.json"

if (-not (Test-Path $secretsFile)) {
    Write-Host "Missing secrets.json - copy secrets.json.example and add your key." -ForegroundColor Red
    exit 1
}

$secretsRaw = Get-Content $secretsFile -Raw
if ($secretsRaw -match "PASTE_YOUR_GOOGLE_VISION_API_KEY_HERE") {
    Write-Host "Edit secrets.json and add your real Google Vision API key first." -ForegroundColor Red
    exit 1
}

Set-Location $root
$flutterArgs = @("run", "--dart-define-from-file=secrets.json")
if ($Device) {
    $flutterArgs += @("-d", $Device)
}

Write-Host "Starting app with Vision OCR (debug build)..." -ForegroundColor Cyan
Write-Host "Note: debug build conflicts with release APK. Use install_android_release.ps1 for release testing." -ForegroundColor Yellow
flutter @flutterArgs

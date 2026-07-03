# Deep uninstall + install release APK. Shows exact Android error if install fails.
#
# Usage:
#   .\tools\install_android_release.ps1
#   .\tools\install_android_release.ps1 -Device 192.168.1.3:46693

param(
    [string]$Device = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$apkPath = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
$packageName = "com.example.gilgal_telugu_worship"

$adbCandidates = @(
    "C:\platform-tools\platform-tools\adb.exe",
    "C:\platform-tools\adb.exe",
    "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
)
$adb = $adbCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $adb) {
    Write-Host "adb.exe not found." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $apkPath)) {
    Write-Host "Release APK not found. Run: .\tools\build_android_release.ps1" -ForegroundColor Red
    exit 1
}

$adbTarget = @()
if ($Device) {
    & $adb connect $Device 2>$null | Out-Null
    Start-Sleep -Seconds 2
    $adbTarget = @("-s", $Device)
}

Write-Host "=== Gilgal release installer ===" -ForegroundColor Cyan
Write-Host "IMPORTANT: Close/stop 'flutter run' in all terminals first." -ForegroundColor Yellow
Write-Host ""

$devices = & $adb @adbTarget devices
Write-Host $devices
if ($devices -notmatch "\tdevice" -and $devices -notmatch "device\s*$") {
    Write-Host ""
    Write-Host "No phone connected." -ForegroundColor Red
    Write-Host "Connect USB cable OR run:" -ForegroundColor Yellow
    Write-Host "  .\tools\wireless_adb.ps1 connect 192.168.1.3 YOUR_PORT" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Checking for existing installs..." -ForegroundColor Cyan
$installed = & $adb @adbTarget shell pm list packages 2>$null | Select-String $packageName
if ($installed) {
    Write-Host "Found: $installed" -ForegroundColor Yellow
} else {
    Write-Host "No active package found (good)." -ForegroundColor Green
}

$retained = & $adb @adbTarget shell pm list packages -u 2>$null | Select-String $packageName
if ($retained) {
    Write-Host "Retained/uninstalled data: $retained" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Removing from all users..." -ForegroundColor Cyan
& $adb @adbTarget shell pm uninstall --user 0 $packageName 2>$null
& $adb @adbTarget shell pm uninstall $packageName 2>$null

# Work profile / secondary user (user 10 is common on some devices)
foreach ($userId in @(10, 11, 999)) {
    & $adb @adbTarget shell pm uninstall --user $userId $packageName 2>$null | Out-Null
}

Start-Sleep -Seconds 1
$stillThere = & $adb @adbTarget shell pm list packages 2>$null | Select-String $packageName
if ($stillThere) {
    Write-Host ""
    Write-Host "Package STILL on phone: $stillThere" -ForegroundColor Red
    Write-Host "On your phone:" -ForegroundColor Yellow
    Write-Host "  1. Settings > Apps > search 'Gilgal' > Uninstall" -ForegroundColor White
    Write-Host "  2. Check Dual Apps / Secure Folder / Work profile for a second copy" -ForegroundColor White
    Write-Host "  3. Reboot phone, then run this script again" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Installing release APK..." -ForegroundColor Cyan
Write-Host "  $apkPath" -ForegroundColor Gray
$output = & $adb @adbTarget install -r -d $apkPath 2>&1
Write-Host $output

if ($output -match "Success") {
    Write-Host ""
    Write-Host "Installed successfully!" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "Install FAILED. Common causes:" -ForegroundColor Red
Write-Host "  - Debug app reinstalled by 'flutter run' (stop it first)" -ForegroundColor Yellow
Write-Host "  - Old debug APK still on phone in Dual Apps / Work profile" -ForegroundColor Yellow
Write-Host "  - Wrong APK file (use app-release.apk only, not app-debug.apk)" -ForegroundColor Yellow
exit 1

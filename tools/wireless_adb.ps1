# Wireless ADB helper for Gilgal app
# Usage:
#   .\tools\wireless_adb.ps1 pair   192.168.1.3 45121 123456
#   .\tools\wireless_adb.ps1 connect 192.168.1.3 5555
#   .\tools\wireless_adb.ps1 devices

$adbCandidates = @(
    "C:\platform-tools\platform-tools\adb.exe",
    "C:\platform-tools\adb.exe",
    "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
)

$adb = $adbCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $adb) {
    Write-Host "adb.exe not found. Install platform-tools or Android SDK." -ForegroundColor Red
    exit 1
}

Write-Host "Using: $adb" -ForegroundColor Cyan
& $adb kill-server | Out-Null
& $adb start-server | Out-Null

$cmd = $args[0]
switch ($cmd) {
    "pair" {
        if ($args.Count -lt 4) {
            Write-Host "Usage: .\tools\wireless_adb.ps1 pair <ip> <pairing-port> <6-digit-code>"
            exit 1
        }
        $endpoint = "$($args[1]):$($args[2])"
        $code = $args[3]
        Write-Host "Pairing with $endpoint ..."
        & $adb pair $endpoint $code
    }
    "connect" {
        if ($args.Count -lt 3) {
            Write-Host "Usage: .\tools\wireless_adb.ps1 connect <ip> <port>"
            exit 1
        }
        $endpoint = "$($args[1]):$($args[2])"
        Write-Host "Connecting to $endpoint ..."
        & $adb connect $endpoint
        & $adb devices -l
    }
    "devices" {
        & $adb devices -l
    }
    default {
        Write-Host @"
Wireless ADB helper

1) On phone: Developer options -> Wireless debugging -> ON
2) Tap 'Pair device with pairing code' -> note IP, port, and 6-digit code
   .\tools\wireless_adb.ps1 pair 192.168.1.3 45121 123456

3) Back on Wireless debugging screen -> note 'IP address & port' (main port)
   .\tools\wireless_adb.ps1 connect 192.168.1.3 5555

4) Check connection:
   .\tools\wireless_adb.ps1 devices

5) Run app:
   cd E:\Gilgal_telugu_worship
   flutter run
"@
    }
}

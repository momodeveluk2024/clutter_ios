# Runs the Flutter app on a USB-connected Android device with the Docker
# backend on this PC reachable as `localhost` from the phone.
#
# Usage:
#   .\run_phone.ps1                # uses adb reverse (default)
#   .\run_phone.ps1 -Lan           # uses your PC's LAN IP instead
#   .\run_phone.ps1 -Lan -Ip 192.168.1.42
#
# Make sure: USB debugging is on, the phone is authorized (`adb devices`
# shows it as "device" not "unauthorized"), and Docker is up:
#   docker compose --profile api up -d
param(
    [switch]$Lan,
    [string]$Ip
)

$ErrorActionPreference = "Stop"

function Get-LanIp {
    $candidate = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notmatch '^127\.' -and
            $_.IPAddress -notmatch '^169\.254\.' -and
            $_.PrefixOrigin -ne 'WellKnown' -and
            $_.AddressState -eq 'Preferred'
        } |
        Sort-Object -Property InterfaceMetric |
        Select-Object -First 1
    if ($null -eq $candidate) {
        throw "Could not detect a LAN IP. Pass one with -Ip 192.168.x.x"
    }
    return $candidate.IPAddress
}

if ($Lan) {
    if ([string]::IsNullOrWhiteSpace($Ip)) {
        $Ip = Get-LanIp
    }
    $apiUrl = "http://$Ip`:8080/v1"
    Write-Host "Using LAN URL: $apiUrl" -ForegroundColor Green
    flutter run --dart-define=NUTRIVITA_API_URL=$apiUrl
}
else {
    Write-Host "Forwarding device localhost:8080 to PC localhost:8080..." -ForegroundColor Green
    adb reverse tcp:8080 tcp:8080
    if ($LASTEXITCODE -ne 0) {
        throw "adb reverse failed. Check 'adb devices' — is your phone authorized?"
    }
    flutter run
}

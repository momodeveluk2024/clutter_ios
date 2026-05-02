param(
    [string]$DatabaseUrl = $env:DATABASE_URL,
    [string]$OutputDir = "backups"
)

if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
    Write-Error "DATABASE_URL or -DatabaseUrl is required."
    exit 1
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputPath = Join-Path $OutputDir "nutrivita-$timestamp.dump"

pg_dump --format=custom --no-owner --no-acl --file $outputPath $DatabaseUrl
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "Backup written to $outputPath"

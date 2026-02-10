<#
run-lighthouse.ps1

Runs Lighthouse (PWA/installable focused) for your deployed site and saves an HTML report.
Requires Node (for npx) and Chrome/Chromium installed locally.

Usage:
  powershell -ExecutionPolicy Bypass -File .\scripts\run-lighthouse.ps1 -url "https://csgapp.github.io/csg/"
#>
param(
  [Parameter(Mandatory=$false)]
  [string]$url = 'https://csgapp.github.io/csg/'
)

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
  Write-Error "npx not found. Install Node.js (includes npx) and re-run this script."
  exit 1
}

$report = Join-Path (Get-Location) "lighthouse-installability-report.html"
Write-Host "Running Lighthouse for $url (this may take a minute)..."
# Use a repo-local temp dir to avoid permission / locking issues on system Temp
$tempDir = Join-Path (Get-Location) '.lighthouse-temp'
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
$env:TEMP = $tempDir
$env:TMP = $tempDir
$exitCode = 1
try {
  & npx -y lighthouse $url --only-categories=best-practices --chrome-flags="--headless --no-sandbox --disable-gpu --disable-dev-shm-usage" --no-enable-error-reporting --output html --output-path $report
  $exitCode = $LASTEXITCODE
} finally {
  Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}
if ($exitCode -eq 0) { Write-Host "Lighthouse finished. Report: $report" } else { Write-Error "Lighthouse failed. Check your environment and that Chrome is installed." }
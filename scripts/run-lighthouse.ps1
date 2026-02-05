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
& npx -y lighthouse $url --only-categories=pwa --chrome-flags="--headless" --output html --output-path $report
if ($LASTEXITCODE -eq 0) { Write-Host "Lighthouse finished. Report: $report" } else { Write-Error "Lighthouse failed. Check your environment and that Chrome is installed." }
<#
install-git-and-push.ps1

What it does:
- Installs Git for Windows (if not installed) using the official Git for Windows installer
- Adds the installer to PATH for the session if needed
- Configures git global user.name / user.email and credential helper (manager-core)
- Stages the changed icon files and `manifest.json`, commits, and attempts to push

Usage:
1. Open PowerShell (preferably as Administrator) in this repo folder.
2. If execution is restricted, run: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`
3. Run: `./install-git-and-push.ps1`

Notes:
- The script will prompt for values where necessary and will attempt to elevate the installer.
- If there is no remote configured, you'll be asked to provide one (HTTPS or SSH).
#>

# --- Helper functions
function Write-Note($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[ERR]  $msg" -ForegroundColor Red }

# Check current folder
$repoDir = (Get-Location).Path
Write-Note "Repo folder: $repoDir"

# Files we'll commit
$filesToCommit = @('manifest.json','icon-180.png','icon-192.png','icon-512.png')

# Check if git is available
function Test-Git {
    try {
        & git --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-Git)) {
    Write-Warn "Git is not found in PATH. Attempting to download and run the Git for Windows installer..."

    $installerUrl = 'https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe'
    $tempInstaller = Join-Path $env:TEMP 'Git-Installer.exe'

    Write-Note "Downloading Git installer from $installerUrl to $tempInstaller"
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $tempInstaller -UseBasicParsing -ErrorAction Stop
        Write-Ok "Downloaded installer"
    } catch {
        Write-Err "Failed to download installer. Please visit https://git-scm.com/download/win and install Git manually."
        exit 1
    }

    Write-Note "Launching installer (it may ask for elevation)."
    try {
        Start-Process -FilePath $tempInstaller -ArgumentList '/VERYSILENT','/NORESTART' -Verb RunAs -Wait
        Write-Ok "Installer finished."
    } catch {
        Write-Warn "Installer could not be started silently (you may have cancelled elevation). Please run the installer manually: $tempInstaller"
        Write-Note "Pausing so you can run the installer. Press Enter after you've installed Git."
        Read-Host
    }

    # Add typical Git path to session PATH if git still not found
    if (-not (Test-Git)) {
        $possible = @("C:\Program Files\Git\cmd","C:\Program Files (x86)\Git\cmd")
        $found = $possible | Where-Object { Test-Path $_ }
        if ($found) {
            $env:PATH = "$($found[0]);$env:PATH"
            Write-Ok "Added $($found[0]) to PATH for this session."
        }
    }

    if (-not (Test-Git)) {
        Write-Err "Git is still not available. Please restart your shell or install Git manually and re-run this script."
        exit 1
    }
}

# At this point git should exist
$gitVersion = (& git --version) -join " "
Write-Ok "Git available: $gitVersion"

# Configure user.name and user.email if missing
$userName = (& git config --global user.name) -join " ";
$userEmail = (& git config --global user.email) -join " ";
if (-not $userName) {
    $userName = Read-Host "Enter the name to use for git commits (git config --global user.name)"
    & git config --global user.name "$userName"
    Write-Ok "Set user.name to '$userName'"
} else { Write-Note "Existing user.name: $userName" }

if (-not $userEmail) {
    $userEmail = Read-Host "Enter the email to use for git commits (git config --global user.email)"
    & git config --global user.email "$userEmail"
    Write-Ok "Set user.email to '$userEmail'"
} else { Write-Note "Existing user.email: $userEmail" }

# Ensure credential manager is active
& git config --global credential.helper manager-core
Write-Note "Set credential.helper to manager-core"

# Verify repo and files
if (-not (Test-Path '.git')) {
    Write-Warn "This folder does not appear to be a git repository (no .git folder). Cannot push."
    Write-Note "If you want to create a repo and push, run: git init; git remote add origin <url>; then re-run this script."
    exit 1
}

# Check files exist
$missing = $filesToCommit | Where-Object { -not (Test-Path $_) }
if ($missing) {
    Write-Warn "The following expected files are missing: $($missing -join ', ')"
    Write-Note "You can adjust the script or add those files, then re-run."
}

# Stage files that exist
$toStage = $filesToCommit | Where-Object { Test-Path $_ }
if ($toStage) {
    Write-Note "Staging files: $($toStage -join ', ')"
    & git add -- $toStage
} else {
    Write-Warn "No files to stage. Exiting."
    exit 0
}

# Commit
$commitMessage = 'Fix icons: rename files and add PNG manifest entries'
try {
    & git commit -m "$commitMessage" | Out-Null
    Write-Ok "Committed: $commitMessage"
} catch {
    Write-Warn "Nothing to commit or commit failed. If nothing changed, skip to push."
}

# Verify remote
$remotes = (& git remote) -join " "
if (-not $remotes) {
    Write-Warn "No git remote configured. You must add a remote to push.";
    $remoteUrl = Read-Host "Enter the remote URL to add (e.g. https://github.com/you/repo.git) or press Enter to skip"
    if ($remoteUrl) {
        & git remote add origin $remoteUrl
        Write-Ok "Added remote origin: $remoteUrl"
    } else {
        Write-Note "Skipping push. You can add a remote later and push manually."
        exit 0
    }
}

# Determine current branch
$branch = (& git rev-parse --abbrev-ref HEAD) -join " "
Write-Note "Current branch: $branch"

# Push
Write-Note "Attempting to push to origin/$branch"
try {
    & git push -u origin $branch
    Write-Ok "Push succeeded."
} catch {
    Write-Err "Push failed. See error above. You may need to authenticate or set the remote branch manually."
    Write-Note "Common remedies: ensure remote URL is correct and you have permission; or push with: git push -u origin $branch"
    exit 1
}

Write-Ok "All done!"

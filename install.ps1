#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$SkipGit,
    [switch]$SkipTerminalConfiguration
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$RepoOwner = 'AvaSharkawy'
$RepoName = 'windows-dev-bootstrap'
$Branch = 'main'
$RawBase = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"
$BootstrapRoot = Join-Path $HOME '.config\windows-dev-bootstrap'
$ThemePath = Join-Path $BootstrapRoot 'sharkawy.omp.json'

function Write-Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "[!] $Message" -ForegroundColor Yellow }
function Test-Command([string]$Name) { return [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

function Install-WingetPackage([string]$Id) {
    Write-Step "Package: $Id"
    & winget list --id $Id --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$Id already installed"
        return
    }

    & winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget failed to install $Id (exit $LASTEXITCODE)." }
    Write-Ok "$Id installed"
}

function Backup-File([string]$Path) {
    if (Test-Path $Path) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backup = "$Path.windows-dev-bootstrap.$stamp.bak"
        Copy-Item $Path $backup -Force
        Write-Ok "Backup: $backup"
    }
}

Write-Host @'

============================================================
               WINDOWS DEV BOOTSTRAP
============================================================
 PowerShell 7 | Windows Terminal | Oh My Posh | PSReadLine
 Meslo Nerd Font | Git | Predictive IntelliSense
============================================================
'@ -ForegroundColor Cyan

if ($env:OS -ne 'Windows_NT') { throw 'This bootstrap currently supports Windows only.' }

Write-Step 'Checking winget'
if (-not (Test-Command 'winget')) {
    throw @'
winget is not available. Install or update Microsoft App Installer, then rerun this script.
'@
}
Write-Ok 'winget available'

Install-WingetPackage 'Microsoft.PowerShell'
Install-WingetPackage 'Microsoft.WindowsTerminal'
Install-WingetPackage 'JanDeDobbeleer.OhMyPosh'
if (-not $SkipGit) { Install-WingetPackage 'Git.Git' }
Refresh-Path

Write-Step 'Verifying PowerShell 7 and Oh My Posh'
if (-not (Test-Command 'pwsh')) { throw 'PowerShell 7 was installed but pwsh is not visible on PATH. Close this shell and rerun the installer.' }
if (-not (Test-Command 'oh-my-posh')) { throw 'Oh My Posh was installed but is not visible on PATH. Close this shell and rerun the installer.' }
$pwshVersion = & pwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
Write-Ok "PowerShell $pwshVersion"
Write-Ok "Oh My Posh $(& oh-my-posh version)"

Write-Step 'Installing Meslo Nerd Font'
try {
    & oh-my-posh font install meslo
    if ($LASTEXITCODE -ne 0) {
        Write-Warn 'Oh My Posh returned a non-zero result while installing Meslo. Setup will continue.'
    } else {
        Write-Ok 'Meslo Nerd Font installed/verified'
    }
} catch {
    Write-Warn "Font installation could not be completed automatically: $($_.Exception.Message)"
}

Write-Step 'Downloading repository-owned theme'
New-Item -ItemType Directory -Path $BootstrapRoot -Force | Out-Null
Invoke-WebRequest "$RawBase/config/sharkawy.omp.json" -OutFile $ThemePath
Write-Ok "Theme: $ThemePath"

Write-Step 'Checking PSReadLine for PowerShell 7'
$psReadLineVersion = (& pwsh -NoLogo -NoProfile -Command "`$m = Get-Module -ListAvailable PSReadLine | Sort-Object Version -Descending | Select-Object -First 1; if (`$m) { `$m.Version.ToString() }").Trim()
if ($psReadLineVersion) {
    Write-Ok "PSReadLine $psReadLineVersion available"
} else {
    Write-Warn 'PSReadLine was not found; installing it for the current user.'
    & pwsh -NoLogo -NoProfile -Command "Install-Module PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck"
    if ($LASTEXITCODE -ne 0) { Write-Warn 'PSReadLine installation returned a non-zero exit code.' }
}

Write-Step 'Installing PowerShell 7 profile'
$PwshProfile = (& pwsh -NoLogo -NoProfile -Command '$PROFILE.CurrentUserCurrentHost').Trim()
$ProfileDir = Split-Path $PwshProfile -Parent
New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
Backup-File $PwshProfile
Invoke-WebRequest "$RawBase/config/Microsoft.PowerShell_profile.ps1" -OutFile $PwshProfile
Write-Ok "Profile: $PwshProfile"

if (-not $SkipTerminalConfiguration) {
    Write-Step 'Configuring Windows Terminal'
    $settingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    $settingsDir = Split-Path $settingsPath -Parent
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null

    try {
        if (Test-Path $settingsPath) {
            Backup-File $settingsPath
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        } else {
            $settings = [pscustomobject]@{}
        }

        if (-not $settings.profiles) {
            $settings | Add-Member NoteProperty profiles ([pscustomobject]@{})
        }
        if (-not $settings.profiles.defaults) {
            $settings.profiles | Add-Member NoteProperty defaults ([pscustomobject]@{})
        }
        if (-not $settings.profiles.defaults.font) {
            $settings.profiles.defaults | Add-Member NoteProperty font ([pscustomobject]@{})
        }

        $settings.profiles.defaults.font | Add-Member NoteProperty face 'MesloLGM Nerd Font' -Force
        $settings | Add-Member NoteProperty defaultProfile '{574e775e-4f2a-5b96-ac1e-a2962a402336}' -Force

        $settings | ConvertTo-Json -Depth 100 | Set-Content $settingsPath -Encoding utf8
        Write-Ok 'Windows Terminal font/default PowerShell 7 profile configured'
    } catch {
        Write-Warn "Windows Terminal settings were not changed: $($_.Exception.Message)"
    }
}

Write-Host @'

============================================================
                    SETUP COMPLETE
============================================================
Close every Windows Terminal window and reopen it.
Use the profile named "PowerShell" (PowerShell 7), not "Windows PowerShell".
============================================================
'@ -ForegroundColor Green

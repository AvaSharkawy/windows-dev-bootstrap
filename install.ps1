#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Green', 'Blue')]
    [string]$Theme = 'Green',
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
$ConfigRoot = Join-Path $BootstrapRoot 'config'

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
 CaskaydiaCove Nerd Font | Git | Predictive IntelliSense
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

Write-Step 'Installing CaskaydiaCove Nerd Font'
try {
    & oh-my-posh font install CascadiaCode
    if ($LASTEXITCODE -ne 0) {
        Write-Warn 'Oh My Posh returned a non-zero result while installing Meslo. Setup will continue.'
    } else {
        Write-Ok 'CaskaydiaCove Nerd Font installed/verified'
    }
} catch {
    Write-Warn "Font installation could not be completed automatically: $($_.Exception.Message)"
}

Write-Step 'Downloading both themes and the theme switcher'
New-Item -ItemType Directory -Path $ConfigRoot -Force | Out-Null
foreach ($file in @('sharkawy.omp.json', 'sharkawy.blue.omp.json', 'sharkawy.terminal.json', 'sharkawy.blue.terminal.json', 'Microsoft.PowerShell_profile.ps1')) {
    $destination = Join-Path $ConfigRoot $file
    Backup-File $destination
    Invoke-WebRequest "$RawBase/config/$file" -UseBasicParsing -OutFile $destination
}
$ThemeScript = Join-Path $BootstrapRoot 'themes.ps1'
Backup-File $ThemeScript
Invoke-WebRequest "$RawBase/themes.ps1" -UseBasicParsing -OutFile $ThemeScript
Write-Ok "Themes: $ConfigRoot"

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
Copy-Item -LiteralPath (Join-Path $ConfigRoot 'Microsoft.PowerShell_profile.ps1') -Destination $PwshProfile -Force
Write-Ok "Profile: $PwshProfile"

if (-not $SkipTerminalConfiguration) {
    Write-Step 'Configuring Windows Terminal'
    $settingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    $settingsDir = Split-Path $settingsPath -Parent
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null

    try {
        if (-not (Test-Path -LiteralPath $settingsPath)) {
            '{}' | Set-Content -LiteralPath $settingsPath -Encoding utf8
        }
        foreach ($color in @('Green', 'Blue')) {
            $arguments = @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ThemeScript, '-Theme', $color, '-NoLaunch', '-SettingsPath', $settingsPath)
            if ($color -eq $Theme) { $arguments += '-SetDefault' }
            & pwsh @arguments
            if ($LASTEXITCODE -ne 0) { throw "Failed to configure $color (exit $LASTEXITCODE)." }
        }
        $themeName = if ($Theme -eq 'Blue') { 'Ava Harbor' } else { 'Ava Grove' }
        Write-Ok "Both themes installed. Default: $themeName"
    } catch {
        Write-Warn "Windows Terminal setup did not finish: $($_.Exception.Message)"
    }
}

Write-Host @'

============================================================
                    SETUP COMPLETE
============================================================
Close every Windows Terminal window and reopen it.
Choose "Ava Grove" or "Ava Harbor" from the profile menu.
============================================================
'@ -ForegroundColor Green

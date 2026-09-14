#Requires -Version 5.1
[CmdletBinding()]
param([switch]$SkipTerminalConfiguration)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$RawBase = 'https://raw.githubusercontent.com/AvaSharkawy/windows-dev-bootstrap/main'
$BootstrapRoot = Join-Path $HOME '.config\windows-dev-bootstrap'
$ConfigRoot = Join-Path $BootstrapRoot 'config'

function Write-Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "[OK] $Message" -ForegroundColor Green }

if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    throw 'PowerShell 7 is not installed. Run install.ps1 instead.'
}

Write-Step 'Updating terminal packages'
foreach ($id in @('Microsoft.PowerShell','Microsoft.WindowsTerminal','JanDeDobbeleer.OhMyPosh','Git.Git')) {
    winget upgrade --id $id --exact --silent --accept-package-agreements --accept-source-agreements
}

$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

Write-Step 'Installing/verifying CaskaydiaCove Nerd Font'
& oh-my-posh font install CascadiaCode
if ($LASTEXITCODE -ne 0) { Write-Warning 'Font installation did not finish. Select an installed Nerd Font in Terminal settings if icons are missing.' }

Write-Step 'Updating all three themes and the theme switcher'
New-Item -ItemType Directory -Path $ConfigRoot -Force | Out-Null
foreach ($file in @('sharkawy.omp.json', 'sharkawy.blue.omp.json', 'sharkawy.terminal.json', 'sharkawy.blue.terminal.json', 'sharkawy.black.omp.json', 'sharkawy.black.terminal.json', 'Microsoft.PowerShell_profile.ps1')) {
    $destination = Join-Path $ConfigRoot $file
    if (Test-Path -LiteralPath $destination) {
        Copy-Item -LiteralPath $destination -Destination "$destination.windows-dev-bootstrap.$(Get-Date -Format 'yyyyMMdd-HHmmss-fff').bak"
    }
    Invoke-WebRequest "$RawBase/config/$file" -UseBasicParsing -OutFile $destination
}
$ThemeScript = Join-Path $BootstrapRoot 'themes.ps1'
if (Test-Path -LiteralPath $ThemeScript) {
    Copy-Item -LiteralPath $ThemeScript -Destination "$ThemeScript.windows-dev-bootstrap.$(Get-Date -Format 'yyyyMMdd-HHmmss-fff').bak"
}
Invoke-WebRequest "$RawBase/themes.ps1" -UseBasicParsing -OutFile $ThemeScript
Write-Ok 'All three themes updated'

Write-Step 'Updating PowerShell profile'
$profilePath = (& pwsh -NoLogo -NoProfile -Command '$PROFILE.CurrentUserCurrentHost').Trim()
$profileDir = Split-Path $profilePath -Parent
New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
if (Test-Path $profilePath) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    Copy-Item $profilePath "$profilePath.windows-dev-bootstrap.$stamp.bak" -Force
}
Copy-Item -LiteralPath (Join-Path $ConfigRoot 'Microsoft.PowerShell_profile.ps1') -Destination $profilePath -Force
Write-Ok 'PowerShell profile updated'

if (-not $SkipTerminalConfiguration) {
    Write-Step 'Registering all three Windows Terminal themes'
    $settingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    if (-not (Test-Path -LiteralPath $settingsPath)) {
        New-Item -ItemType Directory -Path (Split-Path $settingsPath -Parent) -Force | Out-Null
        '{}' | Set-Content -LiteralPath $settingsPath -Encoding utf8
    }
    foreach ($color in @('Green', 'Blue', 'Black')) {
        & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $ThemeScript -Theme $color -NoLaunch -SettingsPath $settingsPath
        if ($LASTEXITCODE -ne 0) { throw "Failed to register $color (exit $LASTEXITCODE)." }
    }
    Write-Ok 'All three themes registered; your default profile is preserved'
}

Write-Host "`nUpdate complete. Restart Windows Terminal." -ForegroundColor Green

#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$RawBase = 'https://raw.githubusercontent.com/AvaSharkawy/windows-dev-bootstrap/main'
$BootstrapRoot = Join-Path $HOME '.config\windows-dev-bootstrap'
$ThemePath = Join-Path $BootstrapRoot 'sharkawy.omp.json'

function Write-Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "[OK] $Message" -ForegroundColor Green }

if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    throw 'PowerShell 7 is not installed. Run install.ps1 instead.'
}

Write-Step 'Updating terminal packages'
foreach ($id in @('Microsoft.PowerShell','Microsoft.WindowsTerminal','JanDeDobbeleer.OhMyPosh','Git.Git')) {
    winget upgrade --id $id --exact --silent --accept-package-agreements --accept-source-agreements
}

Write-Step 'Updating theme'
New-Item -ItemType Directory -Path $BootstrapRoot -Force | Out-Null
Invoke-WebRequest "$RawBase/config/sharkawy.omp.json" -OutFile $ThemePath
Write-Ok 'Theme updated'

Write-Step 'Updating PowerShell profile'
$profilePath = (& pwsh -NoLogo -NoProfile -Command '$PROFILE.CurrentUserCurrentHost').Trim()
$profileDir = Split-Path $profilePath -Parent
New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
if (Test-Path $profilePath) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    Copy-Item $profilePath "$profilePath.windows-dev-bootstrap.$stamp.bak" -Force
}
Invoke-WebRequest "$RawBase/config/Microsoft.PowerShell_profile.ps1" -OutFile $profilePath
Write-Ok 'PowerShell profile updated'

Write-Host "`nUpdate complete. Restart Windows Terminal." -ForegroundColor Green

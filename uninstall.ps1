#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$RemovePackages
)

$ErrorActionPreference = 'Stop'
$BootstrapRoot = Join-Path $HOME '.config\windows-dev-bootstrap'

Write-Host 'Windows Dev Bootstrap cleanup' -ForegroundColor Cyan

if (-not $PSCmdlet.ShouldProcess($BootstrapRoot, 'Remove bootstrap configuration and restore the PowerShell profile')) { return }

$themeScript = Join-Path $BootstrapRoot 'themes.ps1'
$settingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if ((Test-Path -LiteralPath $themeScript) -and (Test-Path -LiteralPath $settingsPath)) {
    foreach ($color in @('Green', 'Blue')) {
        & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $themeScript -Theme $color -Remove -ResetDefault -SettingsPath $settingsPath
        if ($LASTEXITCODE -ne 0) { throw "Could not remove $color from Terminal settings. Configuration files have been kept." }
    }
}

if (Test-Path $BootstrapRoot) {
    Remove-Item $BootstrapRoot -Recurse -Force
    Write-Host "Removed $BootstrapRoot" -ForegroundColor Green
}

if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    $profilePath = (& pwsh -NoLogo -NoProfile -Command '$PROFILE.CurrentUserCurrentHost').Trim()
    if (Test-Path $profilePath) {
        $backup = Get-ChildItem "$profilePath.windows-dev-bootstrap.*.bak" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($backup) {
            Copy-Item $backup.FullName $profilePath -Force
            Write-Host "Restored profile backup: $($backup.FullName)" -ForegroundColor Green
        } else {
            Remove-Item $profilePath -Force
            Write-Host 'Removed bootstrap PowerShell profile.' -ForegroundColor Yellow
        }
    }
}

if ($RemovePackages) {
    Write-Host 'Removing terminal packages requested by -RemovePackages...' -ForegroundColor Yellow
    foreach ($id in @('JanDeDobbeleer.OhMyPosh','Microsoft.WindowsTerminal','Microsoft.PowerShell')) {
        winget uninstall --id $id --exact --silent --accept-source-agreements
    }
    Write-Host 'Git was intentionally left installed.' -ForegroundColor Yellow
}

Write-Host "`nCleanup complete." -ForegroundColor Green

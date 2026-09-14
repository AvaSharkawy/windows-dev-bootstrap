#Requires -Version 7.0
<#
.SYNOPSIS
Register or open an Ava theme in Windows Terminal.
.DESCRIPTION
Adds only the named profile and color scheme, with a settings backup.
The default profile is preserved unless -SetDefault is supplied.
Choose -Theme Green, Blue, or Black (default: Blue). Run with -Remove and the same -Theme to
remove just that theme's entries after closing its windows.
#>
[CmdletBinding(DefaultParameterSetName = 'Preview')]
param(
    [ValidateSet('Green', 'Blue', 'Black')]
    [string]$Theme = 'Blue',
    [string]$StartDirectory = $HOME,
    [Parameter(ParameterSetName = 'Preview')]
    [switch]$SetDefault,
    [Parameter(ParameterSetName = 'Remove')]
    [switch]$Remove,
    [Parameter(ParameterSetName = 'Remove')]
    [switch]$ResetDefault,
    [Parameter(ParameterSetName = 'Preview')]
    [switch]$NoLaunch,
    [Parameter(ParameterSetName = 'Session')]
    [switch]$Session,
    [Parameter(ParameterSetName = 'Preview')]
    [Parameter(ParameterSetName = 'Remove')]
    [string]$SettingsPath = (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json')
)

$ErrorActionPreference = 'Stop'
$themeFile = switch ($Theme) { 'Blue' { 'sharkawy.blue' } 'Black' { 'sharkawy.black' } default { 'sharkawy' } }
$themePath = Join-Path $PSScriptRoot "config\$themeFile.omp.json"
$profilePath = Join-Path $PSScriptRoot 'config\Microsoft.PowerShell_profile.ps1'

if ($Session) {
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        throw 'Oh My Posh is required. Install it with install.ps1 first.'
    }
    . $profilePath -ThemePath $themePath -ColorTheme $Theme
    return
}

$preset = Get-Content -LiteralPath (Join-Path $PSScriptRoot "config\$themeFile.terminal.json") -Raw | ConvertFrom-Json -AsHashtable
if ($Theme -eq 'Blue') {
    $previewGuid = '{b72c07cc-270d-4f64-92dc-83705a6fa9a5}'
    $previewName = 'Ava Harbor'
    $legacySchemeName = 'Sharkawy Harbor Preview'
} elseif ($Theme -eq 'Black') {
    $previewGuid = '{99e9aebe-fcc4-44db-9b21-a935f0826245}'
    $previewName = 'Ava Midnight'
    $legacySchemeName = $null
} else {
    # Retain the original preview GUID so upgrading it creates no duplicate.
    $previewGuid = '{60b00d5e-af83-4f68-8125-83d83de4e97a}'
    $previewName = 'Ava Grove'
    $legacySchemeName = 'Sharkawy Grove Preview'
}

if (-not (Test-Path -LiteralPath $SettingsPath -PathType Leaf)) {
    throw "Windows Terminal settings were not found at '$SettingsPath'. Open Windows Terminal once, or pass -SettingsPath for your installation."
}

# PowerShell 7 accepts Windows Terminal's JSON comments and trailing commas.
# A malformed settings file fails before a backup or any write occurs.
$originalJson = Get-Content -LiteralPath $SettingsPath -Raw
$settings = $originalJson | ConvertFrom-Json -AsHashtable
if ($settings -isnot [System.Collections.IDictionary]) { throw 'Terminal settings must be a JSON object.' }
if (-not $settings.Contains('profiles')) { $settings.profiles = @{} }
if ($settings.profiles -isnot [System.Collections.IDictionary]) { throw 'Terminal profiles must be a JSON object.' }

if (-not $Remove) {
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) { throw 'Oh My Posh is required for the preview.' }
    $pwshPath = (Get-Command pwsh -ErrorAction Stop).Source
    if (-not $NoLaunch) { $terminalPath = (Get-Command wt -ErrorAction Stop).Source }

    $previewProfile = $preset.profile
    $previewProfile.guid = $previewGuid
    $previewProfile.name = $previewName
    $previewProfile.hidden = $false
    $previewProfile.startingDirectory = $StartDirectory
    $previewProfile.commandline = '"{0}" -NoLogo -NoProfile -NoExit -File "{1}" -Session -Theme {2}' -f $pwshPath, $PSCommandPath, $Theme
    $previewProfile.suppressApplicationTitle = $true
    $previewProfile.tabTitle = $previewName
}

$originalProfiles = @($settings.profiles.list | Where-Object { $_ })
$originalSchemes = @($settings.schemes | Where-Object { $_ })
$settings.profiles.list = @($originalProfiles | Where-Object { $_.guid -ne $previewGuid })
$managedSchemeNames = @($preset.scheme.name, $legacySchemeName)
$settings.schemes = @($originalSchemes | Where-Object { $_.name -notin $managedSchemeNames })
if ($Remove) {
    if ($settings.profiles.list.Count -eq $originalProfiles.Count -and $settings.schemes.Count -eq $originalSchemes.Count) {
        Write-Host 'No entries for this theme are installed.'
        return
    }
    if ($settings.defaultProfile -eq $previewGuid) {
        if ($ResetDefault) {
            $settings.defaultProfile = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
        } else {
            throw 'This theme is your default profile. Choose a different default before removing it, or pass -ResetDefault to return to PowerShell 7.'
        }
    }
} else {
    $settings.profiles.list += $previewProfile
    $settings.schemes += $preset.scheme
    if ($SetDefault) { $settings.defaultProfile = $previewGuid }
}

# Retire unused legacy palette names, but preserve shared palettes and user
# edits when another profile still references them, including nested settings.
foreach ($scheme in @($originalSchemes | Where-Object { $_.name -in $managedSchemeNames })) {
    if (@($settings.schemes | Where-Object name -eq $scheme.name).Count -eq 0 -and
        ($settings | ConvertTo-Json -Depth 100).Contains(('"{0}"' -f $scheme.name))) {
        $settings.schemes += $scheme
    }
}

$updatedJson = $settings | ConvertTo-Json -Depth 100
$backupPath = '{0}.windows-dev-bootstrap.{1}.bak' -f $SettingsPath, (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
# Refuse to overwrite changes made by Windows Terminal while preparing the preview.
if ((Get-Content -LiteralPath $SettingsPath -Raw) -cne $originalJson) {
    throw 'Terminal settings changed while preparing the preview. Rerun the command.'
}
Copy-Item -LiteralPath $SettingsPath -Destination $backupPath -ErrorAction Stop
Set-Content -LiteralPath $SettingsPath -Value $updatedJson -Encoding utf8
Write-Host "Settings backup: $backupPath"

if ($Remove) {
    Write-Host "$Theme theme entries removed."
} elseif ($NoLaunch) {
    Write-Host "Theme ready. Open '$previewName' from Windows Terminal's profile menu."
} else {
    & $terminalPath -w new new-tab -p $previewGuid
    if ($LASTEXITCODE -ne 0) { throw "Preview was saved, but Windows Terminal could not open it (exit $LASTEXITCODE)." }
    Write-Host "$Theme theme opened."
}

#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$themeScript = Join-Path $repoRoot 'themes.ps1'
$previewScript = Join-Path $repoRoot 'preview.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('windows-dev-bootstrap-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$settingsFile = Join-Path $testRoot 'settings.json'
$greenGuid = '{60b00d5e-af83-4f68-8125-83d83de4e97a}'
$blueGuid = '{b72c07cc-270d-4f64-92dc-83705a6fa9a5}'

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

# Registration only needs to locate the executable; it must not run it.
# The renderer is checked separately against a real installed Oh My Posh.
function oh-my-posh { throw 'Registration unexpectedly executed Oh My Posh.' }

try {
    $fixture = '{"defaultProfile":"{original}","copyOnSelect":true,"actions":[{"command":"paste"}],"profiles":{"defaults":{"font":{"face":"Existing Font"}},"list":[{"guid":"{original}","name":"Original","customKey":42}]},"schemes":[]}'
    Set-Content -LiteralPath $settingsFile -Value $fixture
    $originalHash = (Get-FileHash -LiteralPath $settingsFile).Hash
    & $previewScript -Theme Green -NoLaunch -SettingsPath $settingsFile 6>$null
    $backup = Get-ChildItem -LiteralPath $testRoot -Filter '*.bak' | Select-Object -First 1
    Assert ($backup -and (Get-FileHash -LiteralPath $backup.FullName).Hash -eq $originalHash) 'Settings backup is not an exact copy.'
    & $themeScript -Theme Blue -NoLaunch -SettingsPath $settingsFile 6>$null
    & $themeScript -Theme Blue -NoLaunch -SettingsPath $settingsFile 6>$null
    $settings = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json -AsHashtable
    Assert ($settings.profiles.list.Count -eq 3 -and $settings.schemes.Count -eq 2) 'Repeated registration duplicated a theme.'
    Assert ($settings.defaultProfile -eq '{original}') 'Registration changed the default without -SetDefault.'
    Assert ($settings.profiles.defaults.font.face -eq 'Existing Font' -and $settings.profiles.list[0].customKey -eq 42) 'Existing profile settings changed.'
    Assert ($settings.copyOnSelect -and $settings.actions[0].command -eq 'paste') 'Unrelated settings changed.'
    $green = $settings.profiles.list | Where-Object guid -eq $greenGuid
    $blue = $settings.profiles.list | Where-Object guid -eq $blueGuid
    Assert ($green.startingDirectory -eq $repoRoot) 'Checkout preview starts outside the repository.'
    Assert ($blue.startingDirectory -eq $HOME) 'Installed switcher does not start at home.'
    Assert ($blue.commandline -like '*themes.ps1" -Session -Theme Blue') 'Blue launches the wrong theme or script.'
    $blueBefore = $blue | ConvertTo-Json -Depth 20

    & $themeScript -Theme Green -NoLaunch -SetDefault -SettingsPath $settingsFile 6>$null
    $beforeRemoval = (Get-FileHash -LiteralPath $settingsFile).Hash
    $rejected = $false
    try { & $themeScript -Theme Green -Remove -SettingsPath $settingsFile 6>$null } catch { $rejected = $true }
    Assert ($rejected -and (Get-FileHash -LiteralPath $settingsFile).Hash -eq $beforeRemoval) 'Default removal was not blocked without changing settings.'

    # A customized palette referenced through a light/dark or unfocused setting
    # must survive removal of the managed profile.
    $settings = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json -AsHashtable
    $settings.profiles.list[0].unfocusedAppearance = @{ colorScheme = @{ dark = 'Sharkawy Grove Preview'; light = 'Other' } }
    ($settings.schemes | Where-Object name -eq 'Sharkawy Grove Preview').background = '#223344'
    $settings | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $settingsFile
    & $themeScript -Theme Green -Remove -ResetDefault -SettingsPath $settingsFile 6>$null
    $settings = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json -AsHashtable
    Assert ($settings.defaultProfile -eq '{574e775e-4f2a-5b96-ac1e-a2962a402336}') 'Uninstall did not restore the standard PowerShell default.'
    Assert (($settings.schemes | Where-Object name -eq 'Sharkawy Grove Preview').background -eq '#223344') 'Removing Green lost a shared palette or user edits.'
    $blueAfter = $settings.profiles.list | Where-Object guid -eq $blueGuid | ConvertTo-Json -Depth 20
    Assert ($blueBefore -ceq $blueAfter) 'Removing Green changed Blue.'
    & $themeScript -Theme Blue -Remove -SettingsPath $settingsFile 6>$null
    $beforeNoop = (Get-FileHash -LiteralPath $settingsFile).Hash
    & $themeScript -Theme Blue -Remove -SettingsPath $settingsFile 6>$null
    Assert ((Get-FileHash -LiteralPath $settingsFile).Hash -eq $beforeNoop) 'Removing an absent theme rewrote settings.'

    Set-Content -LiteralPath $settingsFile -Value '{broken'
    $invalidHash = (Get-FileHash -LiteralPath $settingsFile).Hash
    $rejected = $false
    try { & $themeScript -Theme Blue -NoLaunch -SettingsPath $settingsFile 6>$null } catch { $rejected = $true }
    Assert ($rejected -and (Get-FileHash -LiteralPath $settingsFile).Hash -eq $invalidHash) 'Malformed settings were overwritten.'

    # Fresh installation starts with an empty settings object.
    Set-Content -LiteralPath $settingsFile -Value '{}'
    & $themeScript -Theme Blue -NoLaunch -SetDefault -SettingsPath $settingsFile 6>$null
    $fresh = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json -AsHashtable
    Assert ($fresh.defaultProfile -eq $blueGuid -and $fresh.profiles.list.Count -eq 1) 'Fresh installation did not select Blue.'

    $greenPrompt = Get-Content -LiteralPath (Join-Path $repoRoot 'config\sharkawy.omp.json') -Raw
    $bluePrompt = Get-Content -LiteralPath (Join-Path $repoRoot 'config\sharkawy.blue.omp.json') -Raw
    Assert (($greenPrompt -replace '#[0-9A-Fa-f]{6}', '#COLOR') -ceq ($bluePrompt -replace '#[0-9A-Fa-f]{6}', '#COLOR')) 'The two prompt designs differ beyond colors.'
    Write-Output 'PASS: registration, defaults, removal, backups, shared palettes, preview paths, and matching theme layouts.'
} finally {
    # Only delete the files created in this unique, flat test directory.
    Get-ChildItem -LiteralPath $testRoot -File | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
    Remove-Item -LiteralPath $testRoot
}

# Create your own local theme

A theme has three parts: an Oh My Posh prompt, a Windows Terminal palette and
appearance preset, and PSReadLine typing colors. This guide copies Harbor into
a personal **Ava Dusk** theme. Substitute your own name if you prefer.

Install the project first, then run these commands in PowerShell 7. The built-in
`-Theme` parameter accepts only `Blue`, `Green`, and `Black`; copying a JSON file
does not register another choice. A personal theme uses its own launcher and
Terminal profile. To add a built-in choice, see [Contributing](../CONTRIBUTING.md).

## 1. Make a personal copy

Keep personal files outside `~/.config/windows-dev-bootstrap`: the updater
replaces managed files. This example stops if the destination already exists.

```powershell
$source = Join-Path $HOME '.config\windows-dev-bootstrap\config'
$custom = Join-Path $HOME '.config\ava-local-themes\dusk'
if (Test-Path -LiteralPath $custom) { throw "Already exists: $custom" }
New-Item -ItemType Directory -Path $custom -ErrorAction Stop | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'sharkawy.blue.omp.json') -Destination (Join-Path $custom 'dusk.omp.json')
Copy-Item -LiteralPath (Join-Path $source 'sharkawy.blue.terminal.json') -Destination (Join-Path $custom 'dusk.terminal.json')
Copy-Item -LiteralPath (Join-Path $source 'Microsoft.PowerShell_profile.ps1') -Destination (Join-Path $custom 'profile.ps1')
@'
. (Join-Path $PSScriptRoot 'profile.ps1') -ThemePath (Join-Path $PSScriptRoot 'dusk.omp.json') -ColorTheme Blue
'@ | Set-Content -LiteralPath (Join-Path $custom 'start.ps1') -Encoding utf8
```

These copies are independent of future updates, including improvements to the
shared PowerShell profile. You can compare your `profile.ps1` with the installed
version after updating and bring over any fixes you want.

## 2. Edit the colors

Open the copied files in your text editor:

| File | What to change |
| --- | --- |
| `dusk.omp.json` | Prompt foreground colors, including hex colors inside templates. Preserve the segments, icon characters, and spacing. |
| `dusk.terminal.json` | Set both `scheme.name` and `profile.colorScheme` to `Ava Dusk`. Edit the background, foreground, cursor, selection, ANSI palette, and `profile.tabColor`. |
| `profile.ps1` | Edit colors inside the `if ($ColorTheme -eq 'Blue')` block. Shared string, number, and error colors are in the initial `$readLineColors` table. |

The launcher deliberately selects the copied profile's Blue block as a starting
point. There is no need to add `Dusk` to its `ValidateSet`. PSReadLine's selection
uses ANSI RGB escapes: `48;2;R;G;B` sets the background and `38;2;R;G;B` sets the
foreground. Match those to your Terminal selection colors.

Keep the Nerd Font to retain the icons. See [DESIGN.md](../DESIGN.md) for the
shared appearance rules and existing palettes.

## 3. Add it to Windows Terminal

The repository's `.terminal.json` is a wrapper containing `scheme` and `profile`;
do not paste the whole wrapper into Terminal settings. Generate two separate
fragments from your edited preset in the same PowerShell session:

```powershell
$preset = Get-Content -LiteralPath (Join-Path $custom 'dusk.terminal.json') -Raw | ConvertFrom-Json -AsHashtable
$preset.scheme.name = 'Ava Dusk'
$preset.profile.colorScheme = 'Ava Dusk'
$preset.profile.guid = '{' + [guid]::NewGuid().ToString() + '}'
$preset.profile.name = 'Ava Dusk'
$preset.profile.tabTitle = 'Ava Dusk'
$preset.profile.suppressApplicationTitle = $true
$preset.profile.hidden = $false
$preset.profile.startingDirectory = $HOME
$preset.profile.commandline = '"{0}" -NoLogo -NoProfile -NoExit -File "{1}"' -f (Get-Command pwsh -ErrorAction Stop).Source, (Join-Path $custom 'start.ps1')
$preset.scheme | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath (Join-Path $custom 'scheme.fragment.json') -Encoding utf8
$preset.profile | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath (Join-Path $custom 'profile.fragment.json') -Encoding utf8
```

1. Open Windows Terminal **Settings → Open JSON file**. Save a backup copy of
   that file before editing.
2. Append the object from `scheme.fragment.json` to the top-level `schemes`
   array. Create `"schemes": []` at the top level if it is missing.
3. Append the object from `profile.fragment.json` to `profiles.list`. Separate
   objects with commas and keep all existing entries.
4. Save, then choose **Ava Dusk** from the Terminal dropdown.

Generate the GUID once and keep it for this profile. When changing your palette
later, replace its existing scheme/profile entries instead of appending copies.
Prompt and typing-color edits take effect in a newly opened Dusk tab; Terminal
palette changes require copying the updated scheme into settings again.

Harbor remains the default unless you select Dusk in **Settings → Startup →
Default profile**. Updates preserve the separately named Dusk profile and scheme.

## 4. Try it and switch back

Check a home folder, a Git repository, a long command recalled with Up Arrow,
selected text, and a narrow window. Run `Start-Sleep -Seconds 2` to check duration
and `Write-Error 'Theme preview'` to check error readability.

Open Harbor, Grove, or Midnight from the dropdown to switch back. To remove Dusk,
choose another default if needed, close its tabs, delete its profile in Terminal
Settings, and remove its scheme from JSON only if no other profile uses it. You
can then delete your personal Dusk directory. The built-in switcher's `-Remove`
option does not manage personal themes.

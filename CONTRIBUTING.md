# Contributing themes

Community themes are welcome. Fork the repository, create a branch, and open a
pull request with your palette and a preview. You can submit directly; an issue
is useful if you want feedback on an idea first. Accepted themes join the
built-in installer, theme switcher, and README gallery.

For a theme only you will use, follow [the local theme guide](docs/creating-themes.md).

## Design expectations

Read [DESIGN.md](DESIGN.md). Themes share the two-line layout, Nerd Font icons,
folder, Git status, duration, and clock. Change the colors while preserving
spacing and behavior. Keep text, predictions, selections, and errors readable;
retain amber timing/change indicators and coral errors. Ava Harbor remains the
default. Include your palette's name and hex colors in the pull request.

Use a distinct display name such as `Ava Dusk`, a CLI key such as `Purple`, and
a unique, stable profile GUID. These are examples, not currently supported
theme choices. Generate a GUID once with `[guid]::NewGuid()` and commit that
value; never generate a new profile ID each time the switcher runs.

## Integration checklist

Themes are explicitly registered in code; there is no automatic file discovery.
Use Harbor as a reference and cover all of these integration points:

| File | Required change |
| --- | --- |
| `config/<theme>.omp.json` | Copy an existing prompt and change its colors only. |
| `config/<theme>.terminal.json` | Copy a Terminal preset, change its palette and tab color, and give `scheme.name` and `profile.colorScheme` the same unique display name. |
| `themes.ps1` | Extend the `Theme` validation set, file mapping, and profile identity branch. Set a new GUID and display name, with `$legacySchemeName = $null` for a new theme. Keep existing IDs and Blue defaults. |
| `preview.ps1` | Extend the `Theme` validation set. |
| `config/Microsoft.PowerShell_profile.ps1` | Extend `ColorTheme` validation and its filename mapping, and add matching PSReadLine colors, including prediction and selection. |
| `install.ps1` | Extend theme validation, download filenames, registration loop, and display-name mapping. |
| `update.ps1` | Extend download filenames and registration loop; preserve the user's default. |
| `uninstall.ps1` | Extend the removal loop. |
| `tests/themes.Tests.ps1` | Cover the new theme's registration, repeated registration, launch arguments, default preservation, and removal; include it in the prompt layout comparison. |
| `README.md`, `DESIGN.md` | Add the theme, commands, palette description, and any updated collection counts. |
| `docs/images/` | Add a PNG preview and link it in the README gallery. |

Existing `sharkawy.*` filenames are retained for compatibility. New files can
use a descriptive stem such as `ava.dusk`; the script mappings must match it.
Avoid unrelated changes, new dependencies, or changes to existing themes in a
palette contribution.

## Validate your contribution

Run from the checkout in PowerShell 7:

```powershell
pwsh -NoLogo -NoProfile -File .\tests\themes.Tests.ps1
```

The smoke tests use temporary settings files, not your live Terminal settings.
After adding your CLI key, preview it with `./preview.ps1 -Theme Purple`
(substitute your actual key). Preview registration saves a settings backup;
keep the checkout in place while its profile is in use. Do not run the installer
or updater to test unmerged files: they download configuration from `main`.

Check home and folder icons, clean and dirty Git state, staged changes, a failed
command, duration and clock, text selection, history predictions, and Up Arrow
placing the cursor at the end of a recalled command. Resize the window to check
that the right-hand group hides when space is limited.

Include a screenshot or prompt render with representative Git status and the
duration/clock group, using sample paths and data. Identify renders as renders.
In the pull request, describe the palette, attach the preview, and state which
automated and manual checks you completed. Include attribution for borrowed
material and contribute only material you can share under the repository's
[MIT license](LICENSE).

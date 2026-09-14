# Ava terminal appearance

Ava Harbor (Blue) is the default for new installations and commands without an
explicit theme. Ava Grove (Green) and Ava Midnight (Black) are alternatives.
The updater preserves an existing user's chosen default.

Midnight uses a true black background (#000000), silver focus (#D8DCE3), soft
white text (#DEDEDE), muted context (#A0A0A0), and charcoal selection (#303030).
It shares the same layout, icons, font, and spacing; amber and coral retain their
timing/change and error meanings. Its files are `config/sharkawy.black.omp.json`
and `config/sharkawy.black.terminal.json`.

The Windows Terminal / PowerShell prompt shows folder, Git status, command time,
and clock using Nerd Font icons. Keep these four groups; avoid extra identity
badges and cryptic Git punctuation counters.

Ava Grove (Green) and Ava Harbor (Blue) share the same design and feel. Harbor changes colors only:
deep navy background (#0F1B2E), soft blue focus (#9FC7F5), pale blue foreground
(#DCE7F7), muted context (#8FA8C9), lavender-blue branches (#BECAF1), and selection
(#2A4163). Amber duration/working changes and coral errors remain consistent.
Keep layout, icons, spacing, typography, and behavior identical between themes.

The terminal uses a solid charcoal-green surface (#111917), readable foreground
(#DCE8E2), mint focus (#A6DFC3), muted context (#91A8A0), pale blue Git branches
(#B5C9E2), amber working changes and duration (#E6BD87), and coral errors
(#ED9B91). History predictions use #789188; selection uses #31453D.

Use icon-led segments and natural spacing, without filled powerline badges.
Folder/home, Git branch, edit/staged counts, duration, and clock use Nerd Font
icons. Replace raw Git punctuation counters with a pencil and total changed
count, plus a checked-square and total staged count when applicable.
The first line carries the folder and conditional Git state. Duration and a
24-hour clock align right when they fit. A mint chevron on the next line anchors
typing. Failed commands turn the chevron coral without adding another field.
One blank line separates command groups. Keep history intact.

The native font is CaskaydiaCove Nerd Font at 12 points; use a Nerd Font to retain
the icon glyphs. The terminal has 20px horizontal and 16px vertical
padding, a bar cursor, and an opaque background. No motion or imagery is needed.

The source of truth is `config/sharkawy.omp.json`, the PSReadLine colors in
`config/Microsoft.PowerShell_profile.ps1`, and `config/sharkawy.terminal.json`.
`themes.ps1` registers, launches, and removes profiles with a settings backup.
`preview.ps1` uses the same implementation with the checkout as its starting
directory. Defaults remain intact unless explicitly selected with `-SetDefault`.

Harbor's matching files are `config/sharkawy.blue.omp.json` and
`config/sharkawy.blue.terminal.json`. The shared PowerShell profile receives the
selected color to apply matching syntax, prediction, and selection colors.
`preview.ps1 -Theme Green` and `preview.ps1 -Theme Blue` register distinct
Windows Terminal profiles. Switching is done by opening the desired profile
from the Terminal dropdown; existing tabs retain their own selected theme.
The installer deploys all three themes and the switcher under the user's bootstrap
directory; the updater refreshes all three without changing the chosen default.

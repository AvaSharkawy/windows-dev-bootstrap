# Windows Dev Bootstrap

A repeatable Windows terminal bootstrap for a modern PowerShell development environment.

## Installs and configures

- PowerShell 7
- Windows Terminal
- Oh My Posh
- MesloLGM Nerd Font
- PSReadLine predictive suggestions
- Git
- Repository-managed Oh My Posh theme
- PowerShell profile
- Windows Terminal default profile and font

The setup is designed to be safe to rerun. Existing PowerShell profiles and Windows Terminal settings are backed up before they are changed.

## Fresh machine install

Open the built-in **Windows PowerShell** and run:

```powershell
$installer = Join-Path $env:TEMP 'windows-dev-bootstrap.ps1'
Invoke-WebRequest "https://raw.githubusercontent.com/AvaSharkawy/windows-dev-bootstrap/main/install.ps1?v=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" -OutFile $installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $installer
```

`-ExecutionPolicy Bypass` applies only to that child PowerShell process. It does not permanently change the machine execution policy.

After installation finishes, close every terminal window and reopen **Windows Terminal**. The default profile should be **PowerShell 7**.

## Update an existing setup

```powershell
$updater = Join-Path $env:TEMP 'windows-dev-bootstrap-update.ps1'
Invoke-WebRequest "https://raw.githubusercontent.com/AvaSharkawy/windows-dev-bootstrap/main/update.ps1?v=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" -OutFile $updater
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $updater
```

## Uninstall configuration

Remove only the configuration installed by this repository:

```powershell
$uninstaller = Join-Path $env:TEMP 'windows-dev-bootstrap-uninstall.ps1'
Invoke-WebRequest "https://raw.githubusercontent.com/AvaSharkawy/windows-dev-bootstrap/main/uninstall.ps1?v=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" -OutFile $uninstaller
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $uninstaller
```

To also remove PowerShell 7, Windows Terminal, and Oh My Posh:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $uninstaller -RemovePackages
```

Git is intentionally not removed by `-RemovePackages`.

## Repository layout

```text
.
├── install.ps1
├── update.ps1
├── uninstall.ps1
├── config/
│   ├── Microsoft.PowerShell_profile.ps1
│   └── sharkawy.omp.json
├── .gitignore
├── LICENSE
└── README.md
```

## Notes

- The theme is stored in this repository so the prompt appearance does not depend on built-in Oh My Posh theme availability.
- Font files are not stored in the repository; Meslo is installed by Oh My Posh.
- PSReadLine is normally bundled with PowerShell 7. The installer checks for it and installs it only when necessary.
- On supported Windows 11 systems, `winget` is normally provided by Microsoft App Installer. If `winget` is missing, install or update App Installer first, then rerun the bootstrap.

## License

MIT

# Windows Dev Bootstrap - PowerShell 7 profile

$BootstrapRoot = Join-Path $HOME '.config\windows-dev-bootstrap'
$ThemePath = Join-Path $BootstrapRoot 'sharkawy.omp.json'

if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path $ThemePath)) {
    oh-my-posh init pwsh --config $ThemePath | Invoke-Expression
}

if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Windows

    try {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle InlineView
    } catch {
    }

    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function MenuComplete
    Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardChar
}

$Utf8 = [System.Text.UTF8Encoding]::new()
$OutputEncoding = $Utf8
[Console]::InputEncoding = $Utf8
[Console]::OutputEncoding = $Utf8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'

if (-not (Test-Path Alias:ll)) {
    Set-Alias ll Get-ChildItem
}

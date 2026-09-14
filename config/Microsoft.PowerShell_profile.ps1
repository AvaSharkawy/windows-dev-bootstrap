# Windows Dev Bootstrap - PowerShell 7 profile
param(
    [string]$ThemePath,
    [ValidateSet('Green', 'Blue')]
    [string]$ColorTheme = 'Green'
)

$BootstrapRoot = Join-Path $HOME '.config\windows-dev-bootstrap'
if (-not $ThemePath) {
    $themeFile = if ($ColorTheme -eq 'Blue') { 'sharkawy.blue.omp.json' } else { 'sharkawy.omp.json' }
    $ThemePath = Join-Path $BootstrapRoot "config\$themeFile"
    # Support installations made before themes moved into the config directory.
    if (-not (Test-Path -LiteralPath $ThemePath)) {
        $ThemePath = Join-Path $BootstrapRoot $themeFile
    }
}

if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path $ThemePath)) {
    oh-my-posh init pwsh --config $ThemePath | Invoke-Expression
}

if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Windows
    $readLineColors = @{
        Command          = '#A6DFC3'
        Parameter        = '#B5C9E2'
        String           = '#E6BD87'
        Number           = '#D4B8D6'
        Operator         = '#91A8A0'
        Variable         = '#DCE8E2'
        Type             = '#B5C9E2'
        Comment          = '#91A8A0'
        Error            = '#ED9B91'
        InlinePrediction = '#789188'
        Selection        = "`e[48;2;49;69;61m`e[38;2;220;232;226m"
    }
    if ($ColorTheme -eq 'Blue') {
        $readLineColors.Command = '#9FC7F5'
        $readLineColors.Parameter = '#BECAF1'
        $readLineColors.Operator = '#8FA8C9'
        $readLineColors.Variable = '#DCE7F7'
        $readLineColors.Type = '#BECAF1'
        $readLineColors.Comment = '#8FA8C9'
        $readLineColors.InlinePrediction = '#7995B8'
        $readLineColors.Selection = "`e[48;2;42;65;99m`e[38;2;220;231;247m"
    }
    Set-PSReadLineOption -Colors $readLineColors

    try {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle InlineView
    } catch {
    }

    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    # Keep prefix-based history search, but put the cursor after the recalled command.
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
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

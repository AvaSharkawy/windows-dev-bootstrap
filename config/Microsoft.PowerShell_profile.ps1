# Windows Dev Bootstrap - PowerShell 7 profile
param(
    [string]$ThemePath,
    [ValidateSet('Green', 'Blue', 'Black')]
    [string]$ColorTheme = 'Blue'
)

$BootstrapRoot = Join-Path $HOME '.config\windows-dev-bootstrap'
if (-not $ThemePath) {
    $themeFile = switch ($ColorTheme) { 'Blue' { 'sharkawy.blue.omp.json' } 'Black' { 'sharkawy.black.omp.json' } default { 'sharkawy.omp.json' } }
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
    if ($ColorTheme -eq 'Black') {
        $readLineColors.Command = '#D8DCE3'
        $readLineColors.Parameter = '#BBC4D2'
        $readLineColors.Operator = '#A0A0A0'
        $readLineColors.Variable = '#DEDEDE'
        $readLineColors.Type = '#BBC4D2'
        $readLineColors.Comment = '#A0A0A0'
        $readLineColors.InlinePrediction = '#858585'
        $readLineColors.Selection = "`e[48;2;48;48;48m`e[38;2;222;222;222m"
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
    Set-PSReadLineKeyHandler -Key Ctrl+c -ScriptBlock {
        param($key, $arg)
        $line = $null
        $cursor = 0
        $selectionStart = 0
        $selectionLength = 0
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)
        if ($selectionLength -gt 0 -or $line.Length -gt 0 -or [Console]::IsOutputRedirected) {
            # Preserve copying selected input and cancellation of a typed command.
            [Microsoft.PowerShell.PSConsoleReadLine]::CopyOrCancelLine($key, $arg)
            return
        }

        # An editor launched through a file association can keep writing after
        # PowerShell returns. CancelLine would redraw at the old input position,
        # overwriting those logs. With no input to cancel, start a fresh prompt
        # at the actual cursor instead. WriteLine also handles bottom-row scroll.
        [Console]::WriteLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt($null, [Console]::CursorTop)
    }
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

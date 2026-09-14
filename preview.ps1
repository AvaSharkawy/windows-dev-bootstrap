#Requires -Version 7.0
<#
.SYNOPSIS
Open a theme directly from this checkout, starting in the repository folder.
#>
[CmdletBinding(DefaultParameterSetName = 'Preview')]
param(
    [ValidateSet('Green', 'Blue', 'Black')]
    [string]$Theme = 'Blue',
    [Parameter(ParameterSetName = 'Remove')]
    [switch]$Remove,
    [Parameter(ParameterSetName = 'Preview')]
    [switch]$NoLaunch,
    [Parameter(ParameterSetName = 'Session')]
    [switch]$Session,
    [Parameter(ParameterSetName = 'Preview')]
    [Parameter(ParameterSetName = 'Remove')]
    [string]$SettingsPath
)

& (Join-Path $PSScriptRoot 'themes.ps1') @PSBoundParameters -StartDirectory $PSScriptRoot

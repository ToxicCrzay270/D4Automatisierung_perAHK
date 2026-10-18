#Requires -Version 5.1
<#
.SYNOPSIS
Validates the three AHK scripts and tests their current functions without desktop input.
.EXAMPLE
.\Tests\Test-AhkScripts.ps1 -AutoHotkeyPath 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AutoHotkeyPath,
    [ValidateNotNullOrEmpty()]
    [string]$ProjectRoot = (Split-Path -Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'These AutoHotkey tests require Windows.' }
$ahkExecutable = (Resolve-Path -LiteralPath $AutoHotkeyPath).ProviderPath
$projectDirectory = (Resolve-Path -LiteralPath $ProjectRoot).ProviderPath
$version = [Diagnostics.FileVersionInfo]::GetVersionInfo($ahkExecutable)
if ($version.ProductName -notmatch 'AutoHotkey' -or $version.FileMajorPart -lt 2) {
    throw 'AutoHotkeyPath must point to an AutoHotkey v2 executable.'
}
$template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'RegressionHarness.ahk.template'))
$runDirectory = Join-Path ([IO.Path]::GetTempPath()) ('D4AhkTests-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $runDirectory
$utf8 = [Text.UTF8Encoding]::new($false)

function Invoke-AhkCheck {
    param([string]$ScriptPath, [switch]$Validate)
    $logBase = Join-Path $runDirectory ([guid]::NewGuid().ToString('N'))
    $arguments = '/ErrorStdOut=UTF-8 ' + $(if ($Validate) { '/Validate ' }) + '"' + $ScriptPath + '"'
    $process = Start-Process -FilePath $ahkExecutable -ArgumentList $arguments -WindowStyle Hidden `
        -RedirectStandardOutput ($logBase + '.out') -RedirectStandardError ($logBase + '.err') -PassThru
    try {
        if (-not $process.WaitForExit(20000)) {
            $process.Kill()
            $process.WaitForExit()
            throw "AHK check timed out: $ScriptPath"
        }
        $output = [IO.File]::ReadAllText($logBase + '.out', $utf8).Trim()
        $errors = [IO.File]::ReadAllText($logBase + '.err', $utf8).Trim()
        if ($process.ExitCode -ne 0) {
            throw "AHK check failed ($($process.ExitCode)): $ScriptPath`n$output`n$errors"
        }
        if ($output) { Write-Host $output }
        if ($errors) { throw "Unexpected AHK diagnostics: $errors" }
    }
    finally { $process.Dispose() }
}

function Get-AhkFunction {
    param([string]$Source, [string]$Name)
    # Current source style: function declaration and final brace begin in column 1.
    # Refuse changed/ambiguous layouts rather than copying an arbitrary source tail.
    $pattern = '(?ms)^' + [regex]::Escape($Name) + '\([^\r\n]*\)\r?\n\{.*?^\}'
    $found = [regex]::Matches($Source, $pattern)
    if ($found.Count -ne 1) { throw "Expected exactly one function: $Name" }
    return $found[0].Value
}

function ConvertTo-MockedAhk {
    param([string]$Source)
    $names = @('ErstelleStatusAnzeige', 'PixelGetColor', 'MouseMove', 'WinActive', 'InputBox',
        'CoordMode', 'SendMode', 'Critical', 'KeyWait', 'ToolTip', 'MsgBox', 'Thread', 'Click', 'Sleep')
    foreach ($name in $names) {
        $Source = [regex]::Replace($Source, '\b' + $name + '\b', 'Test' + $name)
    }
    # Extra guard for these reviewed source blocks, not a sandbox for arbitrary AHK.
    $forbidden = '\b(?:Gui|MouseGetPos|MouseMove|MouseClick\w*|Click|ControlClick|ControlSend|Send\w*|Run|RunWait|DllCall|ComCall|MsgBox|InputBox|KeyWait|ToolTip|PixelGetColor|PixelSearch|ImageSearch|WinActive|WinActivate|WinSet\w*|SetTimer|Hotkey|A_Clipboard|FileAppend|FileDelete|DirDelete|RegWrite|RegDelete|Download|Shutdown|CoordMode|Critical|Thread|Sleep|ErstelleStatusAnzeige)\b|(?m)^\s*#|::'
    if ($Source -match $forbidden) { throw "Unmocked/unsupported source token: $($Matches[0])" }
    return $Source
}

try {
    foreach ($variant in @('4k', '2k', 'FullHD')) {
        $name = "Occultistin-Cube_automated_$variant.ahk"
        $sourcePath = Join-Path $projectDirectory $name
        $source = [IO.File]::ReadAllText($sourcePath, $utf8)
        foreach ($directive in [regex]::Matches($source, '(?m)^\s*#[^\r\n]+')) {
            if ($directive.Value.Trim() -notmatch '^#(?:Requires AutoHotkey v2\.0|SingleInstance Force|MaxThreadsPerHotkey 1)$') {
                throw "Unsupported directive in ${name}: $($directive.Value.Trim())"
            }
        }
        foreach ($hotkey in @('F6::StarteAblauf("F6")', 'F5::StarteAblauf("F5")', '!F6::ExitApp')) {
            if (-not [regex]::IsMatch($source, '(?m)^' + [regex]::Escape($hotkey) + '\r?$')) {
                throw "Missing expected hotkey in ${name}: $hotkey"
            }
        }
        # Originals are only loaded with /Validate; their startup code never runs.
        Invoke-AhkCheck -ScriptPath $sourcePath -Validate
        Write-Host "PASS syntax: $name"

        $firstHotkey = [regex]::Match($source, '(?m)^(?:F5|F6)::')
        if (-not $firstHotkey.Success) { throw "No startup boundary in $name" }
        $startup = $source.Substring(0, $firstHotkey.Index)
        $startup = [regex]::Replace($startup, '(?m)^\s*#[^\r\n]*(?:\r?\n|$)', '')
        $functions = foreach ($functionName in @('StarteAblauf', 'ErstelleKlickfolge', 'KlickAusfuehren', 'ErkenneCubeVariante', 'CubeVarianteAusFarbe')) {
            Get-AhkFunction -Source $source -Name $functionName
        }
        $mockStartup = ConvertTo-MockedAhk -Source $startup
        $mockFunctions = ConvertTo-MockedAhk -Source ($functions -join "`n`n")
        $harness = $template.Replace('@@STARTUP@@', $mockStartup).Replace('@@FUNCTIONS@@', $mockFunctions)
        $harnessPath = Join-Path $runDirectory ($variant + '-regression.ahk')
        [IO.File]::WriteAllText($harnessPath, $harness, $utf8)
        Invoke-AhkCheck -ScriptPath $harnessPath -Validate
        Invoke-AhkCheck -ScriptPath $harnessPath
    }
    Write-Host 'PASS: all three scripts validated; offline regression checks passed. No original script was executed.'
}
finally {
    # Only remove the unique directory created by this invocation, inside system temp.
    $resolvedRun = [IO.Path]::GetFullPath($runDirectory)
    $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if ($resolvedRun.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -and
        [IO.Path]::GetFileName($resolvedRun) -match '^D4AhkTests-[0-9a-f]{32}$') {
        Remove-Item -LiteralPath $resolvedRun -Recurse -Force
    }
}

@echo off
setlocal
set "AHK_EXE=%~dp0.tools\autohotkey\AutoHotkey64.exe"
if not exist "%AHK_EXE%" set "AHK_EXE=%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe"
if not exist "%AHK_EXE%" set "AHK_EXE=%LocalAppData%\Programs\AutoHotkey\v2\AutoHotkey64.exe"
if not exist "%AHK_EXE%" (
    echo AutoHotkey v2 fehlt. Bitte AutoHotkey v2 von https://www.autohotkey.com/ installieren.
    pause
    exit /b 1
)
choice /C 123 /N /M "1: 4K (3840x2160) | 2: 2K (2560x1440) | 3: FullHD (1920x1080) - Auswahl: "
if errorlevel 255 exit /b 1
if errorlevel 3 goto FullHD
if errorlevel 2 goto TwoK
if errorlevel 1 goto FourK
exit /b 1

:FourK
set "SCRIPT_FILE=Occultistin-Cube_automated_4k.ahk"
goto Launch

:TwoK
set "SCRIPT_FILE=Occultistin-Cube_automated_2k.ahk"
goto Launch

:FullHD
set "SCRIPT_FILE=Occultistin-Cube_automated_FullHD.ahk"

:Launch
start "" "%AHK_EXE%" "%~dp0%SCRIPT_FILE%"
exit /b 0

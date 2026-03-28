@echo off
setlocal enabledelayedexpansion

set source=%~dp0.
set target=E:\SteamLibrary\steamapps\common\Warhammer 40,000 DARKTIDE\mods
set excludes=.git scripts types

forfiles /P "%source%" /C "cmd /c if @isdir==TRUE echo @file" > "%temp%\dirs.txt"
for /f "delims=" %%D in (%temp%\dirs.txt) do (
    set skip=0
    for %%E in (%excludes%) do (
        if /i "%%~D"=="%%E" set skip=1
    )
    if "!skip!"=="0" (
        if not exist "%target%\%%~D" mklink /d "%target%\%%~D" "%source%\%%~D"
    )
)

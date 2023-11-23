@echo off
rem Add dmb to your environment path, then move this file to your Mods folder
echo Darktide MOD BUILDER
echo ######################
echo. 
echo Preparing to create a mod.
echo. 

set /p mod_name=Please enter a mod name: 
echo. 

dmb create "%mod_name%"
echo.
pause
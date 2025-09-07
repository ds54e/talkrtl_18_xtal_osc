@echo off
set "DSIM_LICENSE=%USERPROFILE%\AppData\Local\metrics-ca\dsim-license.json"
cd "C:\Program Files\Altair\DSim\2025.1"
call shell_activate.bat
cd %~dp0
dsim -f options.txt
pause
exit
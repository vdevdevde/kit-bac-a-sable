@echo off
rem Installe le kit Bac a sable (voir installer.ps1)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File installer.ps1
pause

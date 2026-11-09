@echo off
rem Recree les fichiers du bac a sable et les raccourcis (voir mettre_a_jour.ps1)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File mettre_a_jour.ps1
pause

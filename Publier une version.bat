@echo off
rem POUR LE PROPRIETAIRE DU DEPOT : publie une nouvelle version (voir publier.ps1)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File publier.ps1
pause

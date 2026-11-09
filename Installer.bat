@echo off
rem Installe le kit Bac a sable (voir installer.ps1)
cd /d "%~dp0"

rem Lance depuis l'interieur du .zip sans l'extraire : Windows n'a sorti que ce fichier.
if not exist "%~dp0installer.ps1" goto pas_extrait
echo "%~dp0" | find /i "\AppData\Local\Temp\" >nul && goto pas_extrait

powershell -NoProfile -ExecutionPolicy Bypass -File installer.ps1
pause
exit /b

:pas_extrait
echo.
echo  ===============================================================
echo   Il faut d'abord EXTRAIRE le fichier .zip :
echo.
echo   1. Ferme cette fenetre.
echo   2. Clic droit sur BacASable-x.y.z.zip  ^>  "Extraire tout..."
echo   3. Choisis un endroit ou le dossier restera
echo      (par exemple Documents), puis "Extraire".
echo   4. Dans le dossier extrait, double-clique sur Installer.bat.
echo  ===============================================================
echo.
pause

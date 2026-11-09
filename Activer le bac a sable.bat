@echo off
rem ================================================================
rem  Active Windows Sandbox (Bac a sable).
rem  Windows va afficher une fenetre "Autoriser cette application ?" :
rem  clique sur OUI. Ensuite, redemarre le PC quand tu es pret.
rem ================================================================
net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
echo Verification de Windows...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$n='Containers-DisposableClientVM'; $ed=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID; try { $f=Get-WindowsOptionalFeature -Online -FeatureName $n -ErrorAction Stop } catch { $f=$null }; if (-not $f) { Write-Host ''; Write-Host ('IMPOSSIBLE : ce Windows (edition ' + $ed + ') ne contient pas le Bac a sable.') -ForegroundColor Red; Write-Host 'Il faut Windows 10 ou 11 Pro, Entreprise ou Education.'; Write-Host 'Windows Famille (Home) ne l''a pas, et on ne peut pas l''ajouter.'; Write-Host 'Pour voir ton edition : Parametres > Systeme > Informations systeme.'; Write-Host 'Pour passer a Pro : Parametres > Systeme > Activation (payant).'; exit 1 }; Write-Host 'Activation en cours (1 a 3 minutes)...'; Enable-WindowsOptionalFeature -Online -FeatureName $n -All -NoRestart | Out-Null; $etat=(Get-WindowsOptionalFeature -Online -FeatureName $n).State; Write-Host ('Etat : ' + $etat) -ForegroundColor Green; Write-Host 'C''est bon : redemarre le PC pour terminer.'"
echo.
pause

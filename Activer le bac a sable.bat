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
echo Activation du Bac a sable en cours (1 a 3 minutes)...
powershell -NoProfile -Command "Enable-WindowsOptionalFeature -Online -FeatureName 'Containers-DisposableClientVM' -All -NoRestart | Out-Null; (Get-WindowsOptionalFeature -Online -FeatureName 'Containers-DisposableClientVM').State"
echo.
echo Si tu vois "EnablePending" ou "Enabled" ci-dessus : c'est bon.
echo Redemarre le PC quand tu es pret, puis dis-le a Claude.
pause
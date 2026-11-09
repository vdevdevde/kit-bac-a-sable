# ====================================================================
#  POUR LE PROPRIÉTAIRE DU DÉPÔT : publie une nouvelle version du kit.
#  Tous ceux qui ont installé le kit la verront proposée au prochain
#  lancement du bac à sable.
#
#  Avant : augmente $VersionKit dans mettre_a_jour.ps1 (ex. 1.2.0 -> 1.3.0),
#          puis enregistre avec git (git add -A ; git commit -m "...").
#  Ensuite : double-clique sur "Publier une version.bat".
#  (-Notes "..." permet de donner les nouveautés sans qu'on te les demande.)
# ====================================================================
param([string]$Notes)
$ErrorActionPreference = 'Stop'
$Racine = $PSScriptRoot
Set-Location $Racine
function Arret([string]$t) { Write-Host $t -ForegroundColor Red; exit 1 }

$texte = Get-Content (Join-Path $Racine 'mettre_a_jour.ps1') -Raw -Encoding UTF8
if ($texte -notmatch "\`$VersionKit = '([0-9.]+)'") { Arret 'VersionKit introuvable dans mettre_a_jour.ps1.' }
$Version = $Matches[1]
$Tag = "v$Version"
Write-Host "Version à publier : $Version"

if (git status --porcelain) { Arret "Des modifications ne sont pas enregistrées. Fais d'abord : git add -A ; git commit -m `"...`"" }
# Version déjà publiée sur GitHub ? (stderr de gh ignoré sans planter PowerShell 5.1)
$ErrorActionPreference = 'Continue'
gh release view $Tag 2>&1 | Out-Null
$DejaPubliee = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = 'Stop'
if ($DejaPubliee) { Arret "La version $Version est déjà publiée. Augmente `$VersionKit dans mettre_a_jour.ps1." }

$Fichiers = @('mettre_a_jour.ps1', 'Mettre a jour.bat', 'maj_auto.ps1', 'lancer.ps1',
              'installer.ps1', 'Installer.bat', 'Activer le bac a sable.bat', 'README.md')
foreach ($f in $Fichiers) { if (-not (Test-Path (Join-Path $Racine $f))) { Arret "Fichier manquant : $f" } }

if (-not $Notes) { $Notes = Read-Host 'Nouveautés de cette version (une phrase)' }
if (-not $Notes) { $Notes = "Version $Version" }

$Zip = Join-Path $env:TEMP "BacASable-$Version.zip"
Remove-Item $Zip -ErrorAction SilentlyContinue
Compress-Archive -Path ($Fichiers | ForEach-Object { Join-Path $Racine $_ }) -DestinationPath $Zip

git push origin HEAD
gh release create $Tag $Zip --title "Bac à sable $Version" --notes $Notes
if ($LASTEXITCODE -ne 0) { Arret 'La publication sur GitHub a échoué.' }
Remove-Item $Zip
Write-Host "Publié ! Tout le monde verra la version $Version au prochain lancement." -ForegroundColor Green

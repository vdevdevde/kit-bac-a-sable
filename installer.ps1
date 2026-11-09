# ====================================================================
#  Installation du kit Bac à sable (double-clique sur Installer.bat)
#  1. vérifie que ce PC peut faire tourner Windows Sandbox ;
#  2. crée le dossier A_tester, les fichiers .wsb et les raccourcis ;
#  3. active Windows Sandbox si besoin (Windows demande "Oui").
# ====================================================================
$Racine = $PSScriptRoot

# Les fichiers extraits d'un .zip téléchargé portent la marque « vient d'internet » :
# Windows redemanderait une confirmation à chaque double-clic. Tu as lancé cet
# installeur en connaissance de cause, donc on retire cette marque, UNIQUEMENT sur
# les fichiers du kit (jamais sur A_tester ni sur autre chose).
foreach ($f in 'mettre_a_jour.ps1', 'Mettre a jour.bat', 'maj_auto.ps1', 'lancer.ps1',
               'installer.ps1', 'Installer.bat', 'Activer le bac a sable.bat', 'README.md') {
    $chemin = Join-Path $Racine $f
    if (Test-Path -LiteralPath $chemin) { Unblock-File -LiteralPath $chemin -ErrorAction SilentlyContinue }
}

function Titre([string]$t) { Write-Host ''; Write-Host "== $t ==" -ForegroundColor Cyan }
function Stop-Installation([string]$t) { Write-Host ''; Write-Host $t -ForegroundColor Red; exit 1 }

Titre 'Vérification du PC'
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "  Windows : $($os.Caption)"
if ($os.Caption -match 'Famille|Home' -or @(98, 99, 100, 101) -contains [int]$os.OperatingSystemSKU) {
    Stop-Installation "Windows Famille (Home) ne contient pas le bac à sable.`nIl faut Windows 10/11 Pro, Entreprise ou Éducation. Installation arrêtée."
}
$cs  = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
if (-not $cs.HypervisorPresent -and -not $cpu.VirtualizationFirmwareEnabled) {
    $option = if ($cpu.Manufacturer -match 'AMD') { '"SVM Mode"' } else { '"Intel Virtualization Technology" (VT-x)' }
    Stop-Installation ("La virtualisation est désactivée dans le BIOS.`n" +
        "Redémarre, appuie sur Suppr (ou F2) pour entrer dans le BIOS, passe en mode avancé,`n" +
        "active $option, enregistre avec F10, puis relance Installer.bat.")
}
Write-Host '  Virtualisation : OK'
$ram = [math]::Round($cs.TotalPhysicalMemory / 1GB)
Write-Host "  Mémoire : $ram Go" $(if ($ram -lt 8) { '(juste : le bac à sable sera lent)' } else { '' })
$libre = [math]::Round((Get-PSDrive C).Free / 1GB)
if ($libre -lt 2) { Stop-Installation "Pas assez de place sur C: ($libre Go libres, il en faut au moins 2)." }

Titre 'Création du kit'
& (Join-Path $Racine 'mettre_a_jour.ps1') -SansMaj
if ($LASTEXITCODE -ne 0) { Write-Host 'Le kit signale un problème (voir ci-dessus).' -ForegroundColor Yellow }

Titre 'Windows Sandbox'
$exe = Join-Path $env:WINDIR 'System32\WindowsSandbox.exe'
if (Test-Path $exe) {
    Write-Host '  Déjà activé. Tout est prêt !' -ForegroundColor Green
    Write-Host '  Double-clique sur "Bac à sable (sécurisé)" sur ton bureau.'
} elseif (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
    Write-Host '  Activation déjà faite : REDÉMARRE le PC pour terminer.' -ForegroundColor Yellow
} else {
    Write-Host '  Activation : Windows va demander "Autoriser cette application ?" -> clique OUI.' -ForegroundColor Yellow
    Start-Process -FilePath (Join-Path $Racine 'Activer le bac a sable.bat') -Wait
    Write-Host ''
    Write-Host '  Quand l''activation est terminée : REDÉMARRE le PC.' -ForegroundColor Yellow
    Write-Host '  Ensuite, double-clique sur "Bac à sable (sécurisé)" sur ton bureau.'
}
Write-Host ''
Write-Host "Mode d'emploi : LISEZ-MOI.txt (dans $Racine)"

# ====================================================================
#  Installation du kit Bac à sable (double-clique sur Installer.bat)
#
#  - Windows 10/11 Pro, Entreprise, Éducation : Windows Sandbox (intégré).
#  - Windows 10/11 Famille (Home) : "mode Famille", une machine virtuelle
#    jetable avec VirtualBox (gratuit). Mêmes protections : pas d'internet,
#    pas de copier-coller, A_tester en lecture seule, et tout est effacé
#    à chaque fermeture (retour à un "instantané" propre).
#
#  -MajVirtualBox : seulement installer / mettre à jour VirtualBox
#                   (utilisé par lancer.ps1 quand VirtualBox est en retard).
# ====================================================================
param([switch]$MajVirtualBox)

$Racine = $PSScriptRoot
$ATester = Join-Path $Racine 'A_tester'
$NomVM = 'BacASable'

function Trouver-VBoxManage {
    $dir = (Get-ItemProperty 'HKLM:\SOFTWARE\Oracle\VirtualBox' -ErrorAction SilentlyContinue).InstallDir
    foreach ($d in @($dir, (Join-Path $env:ProgramFiles 'Oracle\VirtualBox'))) {
        if ($d) { $p = Join-Path $d 'VBoxManage.exe'; if (Test-Path $p) { return $p } }
    }
    return $null
}
function Version-VBox([string]$exe) {
    $l = (& $exe --version 2>$null) | Where-Object { "$_" -match '^\d+\.\d+\.\d+' } | Select-Object -First 1
    if ($l) { return [version]("$l" -replace '^(\d+\.\d+\.\d+).*$', '$1') } else { return $null }
}
function Verifier-Signature([string]$fichier, [string]$editeur) {
    $s = Get-AuthenticodeSignature -FilePath $fichier
    if ($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notmatch [regex]::Escape($editeur)) {
        throw "la signature de $(Split-Path $fichier -Leaf) n'est pas valide (attendu : $editeur) : installation annulée"
    }
}
# Télécharge VirtualBox depuis le site OFFICIEL, vérifie l'empreinte officielle (SHA256)
# et la signature d'Oracle, puis lance l'installation. Rien n'est lancé si un contrôle échoue.
function Installer-VirtualBox {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $base = 'https://download.virtualbox.org/virtualbox'
    $ver = (Invoke-WebRequest "$base/LATEST.TXT" -UseBasicParsing -TimeoutSec 30).Content.Trim()
    if ($ver -notmatch '^\d+\.\d+\.\d+$') { throw "numéro de version inattendu : $ver" }
    $sommes = (Invoke-WebRequest "$base/$ver/SHA256SUMS" -UseBasicParsing -TimeoutSec 30).Content
    $ligne = ($sommes -split "`n") | Where-Object { $_ -match "^[0-9a-f]{64}\s+\*?VirtualBox-$([regex]::Escape($ver))-\d+-Win\.exe\s*$" } | Select-Object -First 1
    if (-not ($ligne -match '^([0-9a-f]{64})\s+\*?(\S+)')) { throw "installeur Windows introuvable pour VirtualBox $ver" }
    $empreinte = $Matches[1]; $nom = $Matches[2]
    $tmp = Join-Path $env:TEMP ('BacASable_vbox_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        Write-Host '  Téléchargement de Visual C++ (Microsoft, nécessaire à VirtualBox)...'
        $vc = Join-Path $tmp 'vc_redist.x64.exe'
        Invoke-WebRequest 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile $vc -UseBasicParsing -TimeoutSec 600
        Verifier-Signature $vc 'Microsoft Corporation'
        Write-Host '  Installation de Visual C++ : Windows va demander "Oui".' -ForegroundColor Yellow
        Start-Process $vc -ArgumentList '/install', '/quiet', '/norestart' -Verb RunAs -Wait

        Write-Host "  Téléchargement de VirtualBox $ver (environ 170 Mo, quelques minutes)..."
        $exe = Join-Path $tmp $nom
        Invoke-WebRequest "$base/$ver/$nom" -OutFile $exe -UseBasicParsing -TimeoutSec 1800
        if ((Get-FileHash $exe -Algorithm SHA256).Hash.ToLower() -ne $empreinte) {
            throw 'le fichier téléchargé ne correspond pas à l''empreinte officielle (abîmé ou modifié) : installation annulée'
        }
        Verifier-Signature $exe 'Oracle'
        Write-Host '  Fichier vérifié : empreinte officielle + signature Oracle. Installation...' -ForegroundColor Green
        Write-Host '  Clique sur Suivant / Oui / Installer. Si on te propose d''installer un "périphérique" Oracle : Installer.' -ForegroundColor Yellow
        Write-Host '  (Un message sur "Python" peut apparaître : clique Oui, ce n''est pas nécessaire.)'
        Start-Process $exe -Wait
    } finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

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

# --- Mode "mise à jour de VirtualBox seulement" (appelé par lancer.ps1)
if ($MajVirtualBox) {
    Titre 'Mise à jour de VirtualBox'
    try { Installer-VirtualBox; Write-Host '  VirtualBox est à jour.' -ForegroundColor Green }
    catch { Write-Host "  Échec : $($_.Exception.Message)" -ForegroundColor Red }
    Read-Host '  Appuie sur Entrée pour fermer'
    exit 0
}

# ---------------------------------------------------------------- PC
Titre 'Vérification du PC'
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "  Windows : $($os.Caption)"
# EditionID ne dépend pas de la langue : Core* = Windows Famille (Home), sans Windows Sandbox.
$Edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).EditionID
Write-Host "  Édition : $Edition"
$Famille = ($Edition -like 'Core*' -or $os.Caption -match 'Famille|Home|Domestique' -or @(98, 99, 100, 101) -contains [int]$os.OperatingSystemSKU)

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
Write-Host "  Mémoire : $ram Go"
$libre = [math]::Round((Get-PSDrive C).Free / 1GB)
if ($Famille) {
    if ($ram -lt 8)   { Stop-Installation "Mode Famille : il faut au moins 8 Go de mémoire (ce PC en a $ram)." }
    if ($libre -lt 40) { Stop-Installation "Mode Famille : il faut au moins 40 Go libres sur C: ($libre Go libres)." }
} elseif ($libre -lt 2) { Stop-Installation "Pas assez de place sur C: ($libre Go libres, il en faut au moins 2)." }

# ---------------------------------------------------------------- Kit
Titre 'Création du kit'
& (Join-Path $Racine 'mettre_a_jour.ps1') -SansMaj
if ($LASTEXITCODE -ne 0) { Write-Host 'Le kit signale un problème (voir ci-dessus).' -ForegroundColor Yellow }

# ================================================================ PRO
if (-not $Famille) {
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
    exit 0
}

# ================================================================ FAMILLE
Titre 'Mode Famille : machine virtuelle jetable (VirtualBox)'
Write-Host '  Windows Famille ne contient pas le bac à sable de Microsoft.'
Write-Host '  On crée à la place un Windows jetable dans VirtualBox (gratuit), avec les'
Write-Host '  mêmes protections. Première installation : 30 à 90 minutes, une seule fois.'

function VBox {
    & $script:VBoxManage @args
    if ($LASTEXITCODE -ne 0) { throw "VBoxManage $($args -join ' ') a échoué (code $LASTEXITCODE)" }
}
function Etat-VM {
    $l = & $script:VBoxManage showvminfo $NomVM --machinereadable 2>$null | Select-String '^VMState="(.+)"'
    if ($l) { return $l.Matches[0].Groups[1].Value } else { return 'absente' }
}

# --- 1. VirtualBox installé et récent ?
$VBoxManage = Trouver-VBoxManage
$VersionVBox = if ($VBoxManage) { Version-VBox $VBoxManage } else { $null }
if (-not $VBoxManage -or -not $VersionVBox -or $VersionVBox -lt [version]'7.0.0') {
    Write-Host ''
    Write-Host '  Étape 1 : installation automatique de VirtualBox (site officiel, fichier vérifié).' -ForegroundColor Yellow
    try { Installer-VirtualBox }
    catch { Stop-Installation "Installation de VirtualBox impossible : $($_.Exception.Message)`nVérifie ta connexion internet, puis relance Installer.bat." }
    $VBoxManage = Trouver-VBoxManage
    $VersionVBox = if ($VBoxManage) { Version-VBox $VBoxManage } else { $null }
    if (-not $VBoxManage -or -not $VersionVBox) { Stop-Installation 'VirtualBox ne semble pas installé (installation annulée ?). Relance Installer.bat.' }
}
Write-Host "  VirtualBox : $VersionVBox"

# --- 2. Machine déjà prête ?
$vms = & $VBoxManage list vms
if ($vms -match "^`"$NomVM`"") {
    $snaps = & $VBoxManage snapshot $NomVM list --machinereadable 2>$null
    if ($snaps -match 'SnapshotName[-0-9]*="propre"') {
        Write-Host '  La machine virtuelle est déjà prête !' -ForegroundColor Green
        Write-Host '  Double-clique sur "Bac à sable (sécurisé)" sur ton bureau.'
        exit 0
    }
    Write-Host '  Une installation précédente n''est pas allée au bout.' -ForegroundColor Yellow
    $rep = Read-Host '  La supprimer et recommencer ? (O/N)'
    if ($rep -notmatch '^[oOyY]') { exit 1 }
    if ((Etat-VM) -eq 'running') { & $VBoxManage controlvm $NomVM poweroff 2>$null | Out-Null; Start-Sleep 5 }
    VBox unregistervm $NomVM --delete
}

# --- 3. Windows utilise déjà l'hyperviseur (protection de la mémoire) ?
#        VirtualBox passe alors par la "Plateforme de l'hyperviseur Windows".
if ($cs.HypervisorPresent) {
    Write-Host ''
    Write-Host '  Windows utilise déjà la virtualisation (protection de la mémoire, c''est bien).' -ForegroundColor Yellow
    Write-Host '  VirtualBox a besoin de la "Plateforme de l''hyperviseur Windows".'
    Write-Host '  Windows va demander "Autoriser cette application ?" -> clique OUI.'
    $resultat = Join-Path $env:TEMP "BacASable_hvp_$([guid]::NewGuid().ToString('N')).txt"
    $cmd = "`$r = Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart; Set-Content -Path '$resultat' -Value `$r.RestartNeeded"
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
    try { Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile -EncodedCommand $enc" } catch { }
    if (-not (Test-Path $resultat)) { Stop-Installation 'Autorisation refusée : impossible de continuer. Relance Installer.bat et clique OUI.' }
    $redemarrer = (Get-Content $resultat) -match 'True'
    Remove-Item $resultat -ErrorAction SilentlyContinue
    if ($redemarrer) { Stop-Installation 'C''est activé. REDÉMARRE le PC, puis relance Installer.bat pour continuer.' }
    Write-Host '  Plateforme de l''hyperviseur : OK'
}

# --- 4. Image de Windows (.iso)
Write-Host ''
Write-Host '  Étape 2 : il faut une image de Windows 11 (fichier .iso, environ 5 Go).' -ForegroundColor Yellow
$Telechargements = try { (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path } catch { Join-Path $env:USERPROFILE 'Downloads' }
function Chercher-Iso {
    Get-ChildItem $Telechargements -Filter *.iso -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'win' -and $_.Length -gt 3GB } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
$Iso = $null
$trouve = Chercher-Iso
if ($trouve) {
    Write-Host "  Image trouvée : $($trouve.Name)"
    if ((Read-Host '  Utiliser ce fichier ? (O/N)') -match '^[oOyY]') { $Iso = $trouve.FullName }
}
if (-not $Iso) {
    Write-Host '  Prends la version GRATUITE et légale de Microsoft : "Windows 11 Entreprise (évaluation)".'
    Write-Host '  Je t''ouvre la page : remplis le formulaire, puis choisis "ISO - Entreprise", 64 bits, Français.'
    Write-Host '  Laisse le fichier dans Téléchargements : je le trouverai tout seul.'
    Start-Process 'https://www.microsoft.com/fr-fr/evalcenter/evaluate-windows-11-enterprise'
    Read-Host '  Quand le téléchargement est TERMINÉ, appuie sur Entrée'
    $trouve = Chercher-Iso
    if ($trouve) { $Iso = $trouve.FullName }
    else {
        Add-Type -AssemblyName System.Windows.Forms
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title = 'Choisis le fichier .iso de Windows 11'
        $dlg.Filter = 'Image Windows (*.iso)|*.iso'
        $dlg.InitialDirectory = $Telechargements
        if ($dlg.ShowDialog() -ne 'OK') { Stop-Installation 'Aucun fichier choisi. Relance Installer.bat quand tu as le .iso.' }
        $Iso = $dlg.FileName
    }
}
Write-Host "  Image : $Iso"

# --- 5. Création de la machine, réglée au plus sûr
Titre 'Création de la machine virtuelle'
try {
    $dossierVMs = ((& $VBoxManage list systemproperties) | Select-String '^Default machine folder:\s+(.+)$').Matches[0].Groups[1].Value.Trim()
    $Vdi = Join-Path $dossierVMs "$NomVM\$NomVM.vdi"
    VBox createvm --name $NomVM --ostype Windows11_64 --register
    # Pas de réseau, pas de copier-coller ni glisser-déposer, pas de son, pas d'USB,
    # pas de bureau à distance, pas d'accélération 3D.
    VBox modifyvm $NomVM --memory 4096 --cpus 2 --vram 128 --firmware efi --tpm-type 2.0 `
        --nic1 none --nic2 none --nic3 none --nic4 none `
        --clipboard-mode disabled --drag-and-drop disabled --audio-enabled off `
        --usb-ohci off --usb-ehci off --usb-xhci off --vrde off `
        --graphicscontroller vboxsvga --accelerate-3d off
    # Démarrage sécurisé (Secure Boot), demandé par Windows 11. Facultatif si non supporté.
    & $VBoxManage modifynvram $NomVM inituefivarstore 2>$null | Out-Null
    & $VBoxManage modifynvram $NomVM enrollmssignatures 2>$null | Out-Null
    & $VBoxManage modifynvram $NomVM enrollorclpk 2>$null | Out-Null
    # Fermer la fenêtre = éteindre (pas de "sauvegarder l'état").
    VBox setextradata $NomVM 'GUI/DefaultCloseAction' 'PowerOff'
    VBox setextradata $NomVM 'GUI/RestrictedCloseActions' 'SaveState,Detach'
    VBox createmedium disk --filename $Vdi --size 65536
    VBox storagectl $NomVM --name SATA --add sata --controller IntelAhci --portcount 4
    VBox storageattach $NomVM --storagectl SATA --port 0 --device 0 --type hdd --medium $Vdi
    VBox storageattach $NomVM --storagectl SATA --port 1 --device 0 --type dvddrive --medium emptydrive

    Titre 'Installation automatique de Windows dans la machine'
    Write-Host '  Une fenêtre VirtualBox va s''ouvrir : NE LA TOUCHE PAS, tout est automatique.'
    Write-Host '  Ça prend 30 à 90 minutes. Laisse aussi cette fenêtre-ci ouverte.'
    VBox unattended install $NomVM "--iso=$Iso" --user=bacasable --password=bacasable `
        "--full-user-name=Bac a sable" --install-additions --locale=fr_FR `
        --hostname=bacasable.local --start-vm=gui

    # Attend que Windows soit installé ET qu'un utilisateur soit connecté (outils VirtualBox actifs).
    $debut = Get-Date
    while ($true) {
        Start-Sleep -Seconds 30
        $minutes = [int]((Get-Date) - $debut).TotalMinutes
        $etat = Etat-VM
        if ($etat -ne 'running') { throw "la machine s'est arrêtée pendant l'installation (état : $etat)" }
        $u = & $VBoxManage guestproperty get $NomVM '/VirtualBox/GuestInfo/OS/LoggedInUsers' 2>$null
        if ("$u" -match 'Value:\s*[1-9]') { break }
        if ($minutes -gt 150) { throw 'installation trop longue (plus de 2 h 30)' }
        Write-Host "  Installation en cours... $minutes min"
    }
    Write-Host '  Windows est installé. Finitions (2 minutes)...' -ForegroundColor Green
    Start-Sleep -Seconds 120

    # Éteint proprement.
    & $VBoxManage controlvm $NomVM acpipowerbutton 2>$null | Out-Null
    $t = 0
    while ((Etat-VM) -ne 'poweroff' -and $t -lt 300) { Start-Sleep 5; $t += 5 }
    if ((Etat-VM) -ne 'poweroff') { & $VBoxManage controlvm $NomVM poweroff 2>$null | Out-Null; Start-Sleep 5 }

    # Retire les images d'installation (.iso) des lecteurs.
    foreach ($l in (& $VBoxManage showvminfo $NomVM --machinereadable)) {
        if ($l -match '^"(.+)-(\d+)-(\d+)"="(.+\.iso)"$') {
            & $VBoxManage storageattach $NomVM --storagectl $Matches[1] --port $Matches[2] --device $Matches[3] --medium emptydrive 2>$null | Out-Null
        }
    }

    # Dossier A_tester partagé en LECTURE SEULE.
    if (-not (Test-Path $ATester)) { New-Item -ItemType Directory -Path $ATester | Out-Null }
    VBox sharedfolder add $NomVM --name A_tester --hostpath $ATester --readonly --automount

    # Instantané "propre" : la machine y revient avant et après chaque utilisation.
    VBox snapshot $NomVM take propre --description 'Etat propre du Bac a sable (ne pas supprimer)'
} catch {
    Stop-Installation ("L'installation a échoué : $($_.Exception.Message)`n" +
        "Relance Installer.bat pour recommencer (il proposera de supprimer l'essai raté).")
}

# Raccourcis recréés avec l'icône de VirtualBox.
& (Join-Path $Racine 'mettre_a_jour.ps1') -SansMaj | Out-Null

Titre 'Terminé !'
Write-Host '  Ton bac à sable (mode Famille) est prêt.' -ForegroundColor Green
Write-Host '  Double-clique sur "Bac à sable (sécurisé)" sur ton bureau.'
Write-Host '  Dans la machine, le dossier A_tester est dans "Ce PC" (lecteur réseau).'
Write-Host '  Si Windows demande un mot de passe dans la machine : bacasable'
Write-Host ''
Write-Host "Mode d'emploi : LISEZ-MOI.txt (dans $Racine)"

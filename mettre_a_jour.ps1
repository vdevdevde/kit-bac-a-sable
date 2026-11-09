# ====================================================================
#  Bac à sable Windows - installation ET mise à jour
#  Double-clique sur "Mettre a jour.bat" (dans ce dossier) pour :
#    - recréer les 2 fichiers .wsb et le LISEZ-MOI à partir des
#      réglages ci-dessous (répare un fichier abîmé ou modifié) ;
#    - garder une copie de l'ancienne version dans _sauvegardes\ ;
#    - vérifier que les réglages de sécurité sont toujours bons ;
#    - recréer les 3 raccourcis du bureau ;
#    - faire un bilan de sécurité du PC (lecture seule) ;
#    - proposer la nouvelle version du kit si elle existe sur GitHub
#      (voir maj_auto.ps1 : rien ne s'installe sans ton accord).
#  Ce script ne demande pas les droits admin.
#
#  -Rapide  : seulement régénérer + vérifier (utilisé par lancer.ps1)
#  -SansMaj : ne pas regarder sur GitHub
# ====================================================================
param([switch]$Rapide, [switch]$SansMaj)

$VersionKit = '1.4.0'

# Copier-coller entre ton PC et le bac à sable : 'Disable' (le plus sûr) ou 'Enable'.
# Activé, un programme dans le bac à sable peut lire ce que tu copies sur ton vrai PC
# (un mot de passe copié par exemple), et l'envoyer sur internet dans la version internet.
$PressePapiers = 'Disable'

$ErrorActionPreference = 'Stop'
$Racine      = $PSScriptRoot
$ATester     = Join-Path $Racine 'A_tester'
$Sauvegardes = Join-Path $Racine '_sauvegardes'
$Journal     = Join-Path $Racine 'journal.txt'
$Bureau      = [Environment]::GetFolderPath('Desktop')
$Horodatage  = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'

function Ecrire-Journal([string]$texte) {
    $ligne = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  ' + $texte
    Add-Content -Path $Journal -Value $ligne -Encoding UTF8
    Write-Host $texte
}

# --- 0. Nouvelle version sur GitHub ? (rien ne s'installe sans ton accord)
if (-not $Rapide -and -not $SansMaj) {
    $MiseAJourFaite = & (Join-Path $Racine 'maj_auto.ps1')
    if ($MiseAJourFaite -eq $true) {
        # Relance la NOUVELLE version de ce script, puis s'arrête.
        & (Join-Path $Racine 'mettre_a_jour.ps1') -SansMaj
        exit $LASTEXITCODE
    }
}

# --- Mémoire : 4 Go si le PC a au moins 16 Go, sinon valeur par défaut
$RamGo = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
if ($RamGo -ge 16) { $LigneMemoire = "`r`n  <MemoryInMB>4096</MemoryInMB>" } else { $LigneMemoire = '' }

function Nouveau-Wsb([string]$reseau, [string]$commentaire) {
    $entete = ''
    if ($commentaire) { $entete = "<!-- $commentaire -->`r`n" }
    return $entete + @"
<Configuration>
  <Networking>$reseau</Networking>
  <VGpu>Disable</VGpu>
  <AudioInput>Disable</AudioInput>
  <VideoInput>Disable</VideoInput>
  <PrinterRedirection>Disable</PrinterRedirection>
  <ClipboardRedirection>$PressePapiers</ClipboardRedirection>
  <ProtectedClient>Enable</ProtectedClient>$LigneMemoire
  <MappedFolders>
    <MappedFolder>
      <HostFolder>$([System.Security.SecurityElement]::Escape($ATester))</HostFolder>
      <SandboxFolder>C:\Users\WDAGUtilityAccount\Desktop\A_tester</SandboxFolder>
      <ReadOnly>true</ReadOnly>
    </MappedFolder>
  </MappedFolders>
</Configuration>
"@
}

$LisezMoi = @'
====================================================================
  BAC À SABLE WINDOWS - MODE D'EMPLOI
====================================================================

Le bac à sable (Windows Sandbox) est un "PC jetable" qui s'ouvre dans
une fenêtre. Ce qui se passe dedans reste dedans, et TOUT est effacé
quand tu fermes la fenêtre.

--------------------------------------------------------------------
1) TESTER UN FICHIER
--------------------------------------------------------------------
  a. AVANT TOUT : envoie le fichier sur https://www.virustotal.com
     Si plusieurs antivirus le signalent, ne va pas plus loin : supprime-le.
  b. Mets le fichier dans le dossier A_tester
     (raccourci "Fichiers à tester" sur ton bureau).
  c. Double-clique sur "Bac à sable (sécurisé)" sur ton bureau.
     Attends que la fenêtre affiche un bureau Windows (30 s à 1 min).
  d. Dans cette fenêtre, ouvre le dossier A_tester qui est sur SON
     bureau, et lance le fichier depuis là.
  e. Quand tu as fini, ferme la fenêtre. Tout est effacé.

Le dossier A_tester est en LECTURE SEULE dans le bac à sable :
un virus ne peut ni modifier ni ajouter de fichier sur ton vrai disque.
Pour qu'un programme puisse s'installer, copie-le d'abord de A_tester
vers le bureau du bac à sable, puis lance la copie.

--------------------------------------------------------------------
2) LES DEUX VERSIONS
--------------------------------------------------------------------
  Bac à sable (sécurisé)  -> SANS internet. À utiliser 95 % du temps.
                             Un virus ne peut rien envoyer.
  Bac à sable (internet)  -> AVEC internet. Seulement pour un installeur
                             qui doit télécharger quelque chose.
                             Un virus PEUT envoyer des données dehors.

Une seule fenêtre de bac à sable peut être ouverte à la fois.

--------------------------------------------------------------------
3) LES LIMITES (IMPORTANT)
--------------------------------------------------------------------
  * Un virus peut détecter qu'il est dans un bac à sable et "faire
    le mort". "Rien ne se passe" NE VEUT PAS DIRE "fichier sain".
    Passe TOUJOURS d'abord par virustotal.com.
  * Ne tape JAMAIS un vrai mot de passe dans le bac à sable
    (Discord, mail, Steam, banque...), surtout dans la version internet.
  * Le copier-coller entre ton PC et le bac à sable est COUPÉ, exprès :
    sinon un virus dans le bac à sable pourrait lire ce que tu copies
    sur ton vrai PC (un mot de passe par exemple).
    Pour un lien, tape-le à la main. Pour un fichier, passe par A_tester.
  * Ne mets JAMAIS dans A_tester un virus déjà identifié (un dossier de
    quarantaine par exemple). Astuce : écris le nom de ces dossiers, un par
    ligne, dans un fichier "interdits.txt" à côté de ce mode d'emploi ;
    "Mettre a jour.bat" te préviendra s'ils se retrouvent dans A_tester.
  * Vide A_tester après tes tests (supprime les fichiers suspects).

  * Un virus PEUT abîmer ce qu'il y a dans A_tester ? Non : ce dossier
    est en lecture seule dans le bac à sable (testé : "Accès refusé").

--------------------------------------------------------------------
3 bis) EST-CE QUE C'EST VRAIMENT SÛR ?
--------------------------------------------------------------------
  Le bac à sable est une vraie machine virtuelle (Hyper-V), la même
  technologie que Microsoft utilise pour isoler ses serveurs. Pour un
  virus "normal", il ne peut PAS sortir. Mais rien n'est sûr à 100 % :
  * De très rares failles ("évasion de machine virtuelle") ont existé.
    Microsoft les corrige dans les mises à jour : garde Windows À JOUR.
    Si Windows n'a pas été mis à jour depuis plus de 45 jours, le
    raccourci refuse de lancer le bac à sable (sauf si tu insistes).
  * La version internet laisse le virus parler à internet : il ne peut
    pas toucher ton PC, mais il peut attaquer d'autres appareils de ta
    box (rare). Utilise-la le moins possible.
  * Ce n'est PAS un outil pour jouer avec des virus connus. C'est un
    filet de sécurité pour un fichier douteux.

--------------------------------------------------------------------
4) SI LE BAC À SABLE NE SE LANCE PAS
--------------------------------------------------------------------
  * "Le fichier .wsb ne s'ouvre avec rien" ou "fonctionnalité absente" :
    la fonctionnalité n'est pas activée. Double-clique sur
    "Installer.bat", clique sur Oui, puis redémarre le PC.
  * Message "Le nom de fonctionnalité Containers-DisposableClientVM est
    inconnu" ou "IMPOSSIBLE" : c'est Windows Famille (Home). Le bac à
    sable n'existe PAS sur cette édition et ne peut pas y être ajouté.
    Il faut Windows 10/11 Pro, Entreprise ou Éducation (Paramètres >
    Système > Activation pour passer à Pro, payant).
  * Message sur la virtualisation : elle doit être activée dans le BIOS.
    Au démarrage du PC, appuie sur Suppr (ou F2) pour entrer dans le BIOS,
    passe en mode avancé, puis cherche :
      - processeur AMD   : "SVM Mode" -> Enabled
      - processeur Intel : "Intel Virtualization Technology" (VT-x) -> Enabled
    (ASUS : Advanced > CPU Configuration ; Gigabyte : Tweaker >
    Advanced CPU Settings ; MSI : OC > CPU Features.) Enregistre (F10).
  * Une fenêtre de bac à sable est déjà ouverte : ferme-la d'abord.
  * Redémarre le PC, puis réessaie.
  * Ton antivirus bloque quelque chose : regarde son historique.
    Ne désactive JAMAIS ton antivirus, le pare-feu ou l'UAC.
  * Un fichier .wsb a été abîmé ou modifié : double-clique sur
    "Mettre a jour.bat" dans ce dossier, il les recrée proprement.

--------------------------------------------------------------------
5) MISE À JOUR
--------------------------------------------------------------------
"Mettre a jour.bat" recrée les fichiers .wsb, ce mode d'emploi et les
raccourcis du bureau, vérifie les réglages de sécurité, et garde
l'ancienne version dans _sauvegardes\, et fait un BILAN DE SÉCURITÉ de
ton PC (antivirus, pare-feu, UAC, isolation, mises à jour) sans rien
modifier. Tout est noté dans journal.txt. Lance-le une fois par mois.

MISE À JOUR AUTOMATIQUE : à chaque ouverture du bac à sable (et à chaque
"Mettre a jour.bat"), le kit regarde s'il existe une nouvelle version sur
GitHub. Si oui, une fenêtre te la propose : clique Oui pour l'installer.
Rien ne s'installe sans ton accord. Sans internet, rien ne se passe.
Tes fichiers (A_tester, interdits.txt, journal.txt) ne sont jamais touchés.

Version du kit : {VERSION}
'@

# --- 1. Dossiers
foreach ($d in @($ATester, $Sauvegardes)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}
Ecrire-Journal "=== Mise à jour du kit (version $VersionKit) ==="

# --- 2. Fichiers (sauvegarde si l'ancien contenu est différent)
$Utf8SansBom = New-Object System.Text.UTF8Encoding($false)
$Utf8AvecBom = New-Object System.Text.UTF8Encoding($true)
$Fichiers = @(
    @{ Nom = 'Sandbox_Securise.wsb'; Contenu = (Nouveau-Wsb 'Disable' ''); Enc = $Utf8SansBom },
    @{ Nom = 'Sandbox_Internet.wsb'; Contenu = (Nouveau-Wsb 'Enable' 'ATTENTION : internet actif. Ne jamais se connecter à un vrai compte (Discord, mail, Steam…) dans cette fenêtre.'); Enc = $Utf8SansBom },
    @{ Nom = 'LISEZ-MOI.txt';        Contenu = ($LisezMoi -replace '\{VERSION\}', $VersionKit); Enc = $Utf8AvecBom }
)
foreach ($f in $Fichiers) {
    $chemin = Join-Path $Racine $f.Nom
    if (Test-Path $chemin) {
        $ancien = [System.IO.File]::ReadAllText($chemin)
        if ($ancien.TrimStart([char]0xFEFF) -eq $f.Contenu) { Ecrire-Journal "  $($f.Nom) : déjà à jour"; continue }
        Copy-Item $chemin (Join-Path $Sauvegardes "$($f.Nom).$Horodatage")
        Ecrire-Journal "  $($f.Nom) : ancienne version sauvegardée dans _sauvegardes"
    }
    [System.IO.File]::WriteAllText($chemin, $f.Contenu, $f.Enc)
    Ecrire-Journal "  $($f.Nom) : écrit"
}

# --- 3. Vérifications de sécurité sur les .wsb
$Problemes = 0
foreach ($nom in 'Sandbox_Securise.wsb', 'Sandbox_Internet.wsb') {
    try { [xml]$x = Get-Content (Join-Path $Racine $nom) -Raw -Encoding UTF8 }
    catch { Ecrire-Journal "  ERREUR : $nom n'est pas du XML valide"; $Problemes++; continue }
    $c = $x.Configuration
    $ok = ($c.MappedFolders.MappedFolder | Where-Object { $_.ReadOnly -ne 'true' }).Count -eq 0 -and
          -not $c.LogonCommand -and $c.VGpu -eq 'Disable' -and $c.ProtectedClient -eq 'Enable' -and
          $c.AudioInput -eq 'Disable' -and $c.VideoInput -eq 'Disable' -and $c.PrinterRedirection -eq 'Disable' -and
          $c.ClipboardRedirection -eq $PressePapiers -and
          ($c.MappedFolders.MappedFolder | Measure-Object).Count -eq 1 -and
          $c.MappedFolders.MappedFolder.HostFolder -eq $ATester
    if ($nom -eq 'Sandbox_Securise.wsb' -and $c.Networking -ne 'Disable') { $ok = $false }
    if ($ok) { Ecrire-Journal "  $nom : XML valide, réglages de sécurité OK" }
    else     { Ecrire-Journal "  ATTENTION : $nom a un réglage de sécurité incorrect"; $Problemes++ }
}
# interdits.txt (facultatif, reste sur ce PC) : un nom de dossier/fichier par ligne
# qui ne doit jamais se retrouver dans A_tester (ex. un dossier de quarantaine).
$FichierInterdits = Join-Path $Racine 'interdits.txt'
if (Test-Path $FichierInterdits) {
    foreach ($nomInterdit in (Get-Content $FichierInterdits -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        if (Test-Path -LiteralPath (Join-Path $ATester $nomInterdit)) {
            Ecrire-Journal "  ATTENTION : '$nomInterdit' (liste interdits.txt) est dans A_tester. Retire-le !"
            $Problemes++
        }
    }
}

# Lancement rapide (lancer.ps1) : on s'arrête là, le code de sortie dit si tout est sûr.
if ($Rapide) { exit $Problemes }

# --- 4. Raccourcis du bureau
# Les 2 raccourcis du bac à sable passent par lancer.ps1, qui vérifie les mises à jour
# et la sécurité des .wsb avant chaque lancement.
$Exe = Join-Path $env:WINDIR 'System32\WindowsSandbox.exe'
$PowerShellExe = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$Lanceur = Join-Path $Racine 'lancer.ps1'
$Shell = New-Object -ComObject WScript.Shell
$Raccourcis = @(
    @{ Nom = 'Bac à sable (sécurisé)'; Profil = 'Securise'; Desc = 'Bac à sable SANS internet' },
    @{ Nom = 'Bac à sable (internet)'; Profil = 'Internet'; Desc = 'Bac à sable AVEC internet - aucun vrai mot de passe !' },
    @{ Nom = 'Fichiers à tester';      Dossier = $ATester;  Desc = 'Dossier des fichiers à tester dans le bac à sable' }
)
foreach ($r in $Raccourcis) {
    $lnk = $Shell.CreateShortcut((Join-Path $Bureau "$($r.Nom).lnk"))
    if ($r.Profil) {
        $lnk.TargetPath = $PowerShellExe
        $lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Lanceur`" -Profil $($r.Profil)"
        $lnk.WorkingDirectory = $Racine
        $lnk.WindowStyle = 7
        if (Test-Path $Exe) { $lnk.IconLocation = "$Exe,0" }
    } else {
        $lnk.TargetPath = $r.Dossier
    }
    $lnk.Description = $r.Desc
    $lnk.Save()
}
Ecrire-Journal "  Raccourcis du bureau : OK ($Bureau)"

# --- 5. État de la fonctionnalité
if (Test-Path $Exe) { Ecrire-Journal "  Windows Sandbox : installé" }
else { Ecrire-Journal "  Windows Sandbox : PAS encore activé (voir LISEZ-MOI, partie 4)" }

# --- 6. Bilan de sécurité du PC (lecture seule, ne modifie rien)
Ecrire-Journal "--- Bilan de sécurité du PC ---"
function Verifier([string]$nom, [scriptblock]$test, [string]$conseil) {
    try { $r = & $test } catch { $r = $null }
    if ($r -eq $true) { Ecrire-Journal "  [OK] $nom" }
    elseif ($r -eq $null) { Ecrire-Journal "  [?]  $nom : impossible à vérifier" }
    else { Ecrire-Journal "  [ATTENTION] $nom : $conseil"; $script:Problemes++ }
}
Verifier 'Antivirus actif et à jour' {
    $av = Get-CimInstance -Namespace root\SecurityCenter2 AntiVirusProduct -ErrorAction Stop
    # productState : octet du milieu 0x10 = activé, octet du bas 0x00 = signatures à jour
    [bool]($av | Where-Object { (($_.productState -shr 8) -band 0x10) -and (($_.productState -band 0xFF) -eq 0) })
} 'aucun antivirus actif et à jour. Ouvre ton antivirus et lance une mise à jour.'
Verifier 'Pare-feu actif' {
    $fw = Get-CimInstance -Namespace root\SecurityCenter2 FirewallProduct -ErrorAction SilentlyContinue
    [bool]($fw | Where-Object { ($_.productState -shr 8) -band 0x10 }) -or
    -not (Get-NetFirewallProfile -ErrorAction Stop | Where-Object { -not $_.Enabled })
} 'pare-feu désactivé. Réactive-le (Sécurité Windows > Pare-feu, ou ton antivirus).'
Verifier 'Contrôle de compte (UAC) actif' {
    (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -ErrorAction Stop).EnableLUA -eq 1
} 'UAC désactivé. Ne lance pas le bac à sable avant de l''avoir réactivé.'
Verifier 'Isolation matérielle (VBS) active' {
    (Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard Win32_DeviceGuard -ErrorAction Stop).VirtualizationBasedSecurityStatus -eq 2
} 'isolation basée sur la virtualisation inactive (Sécurité Windows > Sécurité des appareils > Isolation du noyau).'
Verifier 'Windows mis à jour depuis moins de 45 jours' {
    $d = (Get-HotFix -ErrorAction Stop | Where-Object InstalledOn | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn
    ((Get-Date) - $d).TotalDays -lt 45
} 'mises à jour en retard. Paramètres > Windows Update > Rechercher des mises à jour. C''est ce qui corrige les failles du bac à sable.'
$Contenu = @(Get-ChildItem $ATester -Force -ErrorAction SilentlyContinue)
if ($Contenu.Count -gt 0) { Ecrire-Journal "  [INFO] A_tester contient $($Contenu.Count) élément(s) : pense à le vider après tes tests." }

if ($Problemes -eq 0) { Ecrire-Journal "Terminé, tout est OK." }
else { Ecrire-Journal "Terminé avec $Problemes problème(s) : lis les lignes ATTENTION ci-dessus." }
exit $Problemes

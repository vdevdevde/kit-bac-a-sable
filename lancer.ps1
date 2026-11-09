# ====================================================================
#  Lance le bac à sable (utilisé par les raccourcis du bureau).
#  Avant chaque lancement :
#    1. propose la nouvelle version du kit si elle existe (GitHub) ;
#    2. recrée et vérifie les réglages de sécurité ;
#    3. bloque si Windows (ou VirtualBox) n'est pas à jour ;
#    4. refuse de lancer si un seul réglage n'est pas sûr.
#  Deux modes :
#    - Windows Sandbox (Windows Pro / Entreprise / Éducation) ;
#    - mode Famille : machine virtuelle VirtualBox "BacASable", remise à
#      son instantané propre AVANT et APRÈS chaque utilisation.
# ====================================================================
param([ValidateSet('Securise', 'Internet')][string]$Profil = 'Securise')

$Racine  = $PSScriptRoot
$ATester = Join-Path $Racine 'A_tester'
$NomVM   = 'BacASable'
Add-Type -AssemblyName System.Windows.Forms

function Fenetre([string]$texte, [string]$boutons = 'OK', [string]$icone = 'Information', [string]$defaut = 'Button1') {
    [System.Windows.Forms.MessageBox]::Show($texte, 'Bac à sable', $boutons, $icone, $defaut)
}
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

# Vérifie les réglages de la machine virtuelle. Renvoie la liste des problèmes (vide = sûr).
# $machine : sortie de "showvminfo --machinereadable" ; $humain : sortie de "showvminfo".
function Verifier-VM([string[]]$machine, [string]$humain, [string]$profil, [string]$dossier) {
    $p = New-Object System.Collections.Generic.List[string]
    $v = @{}
    foreach ($l in $machine) { if ($l -match '^"?([^"=]+)"?="?(.*?)"?$') { $v[$Matches[1]] = $Matches[2] } }
    $reseauAttendu = if ($profil -eq 'Internet') { 'nat' } else { 'none' }
    if ($v['nic1'] -ne $reseauAttendu) { $p.Add("réseau 1 = '$($v['nic1'])' au lieu de '$reseauAttendu'") }
    foreach ($n in 2..8) { if ($v.ContainsKey("nic$n") -and $v["nic$n"] -ne 'none') { $p.Add("réseau $n actif") } }
    $presse = @($v['clipboard'], $v['clipboard-mode'], $v['clipboard_mode']) | Where-Object { $_ }
    if (-not $presse -or ($presse | Where-Object { $_ -ne 'disabled' })) { $p.Add('copier-coller pas coupé') }
    $glisser = @($v['draganddrop'], $v['drag-and-drop']) | Where-Object { $_ }
    if (-not $glisser -or ($glisser | Where-Object { $_ -ne 'disabled' })) { $p.Add('glisser-déposer pas coupé') }
    foreach ($k in 'vrde', 'usb', 'ehci', 'xhci') { if ($v.ContainsKey($k) -and $v[$k] -ne 'off') { $p.Add("$k actif") } }
    $partages = @($v.Keys | Where-Object { $_ -like 'SharedFolderNameMachineMapping*' -or $_ -like 'SharedFolderNameTransientMapping*' })
    if ($partages.Count -ne 1 -or $v['SharedFolderNameMachineMapping1'] -ne 'A_tester') { $p.Add('dossiers partagés incorrects') }
    elseif ($v['SharedFolderPathMachineMapping1'] -ne $dossier) { $p.Add('le dossier partagé ne pointe pas sur A_tester') }
    elseif ($humain -notmatch "Name:\s*'A_tester'[^\r\n]*readonly") { $p.Add('A_tester n''est pas en lecture seule') }
    return ,$p
}

# --- Quel mode ?
$Mode = $null
if (Test-Path (Join-Path $env:WINDIR 'System32\WindowsSandbox.exe')) { $Mode = 'Sandbox' }
else {
    $VBoxManage = Trouver-VBoxManage
    if ($VBoxManage -and ((& $VBoxManage snapshot $NomVM list --machinereadable 2>$null) -match 'SnapshotName[-0-9]*="propre"')) { $Mode = 'VirtualBox' }
}
if (-not $Mode) {
    Fenetre "Le bac à sable n'est pas encore installé sur ce PC.`n`nDouble-clique sur Installer.bat (dans $Racine) et suis les étapes." 'OK' 'Warning' | Out-Null
    exit 1
}

# 1. Mise à jour (silencieuse si rien de neuf ou pas d'internet)
try { & (Join-Path $Racine 'maj_auto.ps1') -Silencieux | Out-Null } catch { }

# 2. Régénère + vérifie (lit la version éventuellement mise à jour).
#    Au moindre doute (erreur imprévue comprise), on ne lance PAS.
try { & (Join-Path $Racine 'mettre_a_jour.ps1') -Rapide *> $null; $Code = $LASTEXITCODE } catch { $Code = 99 }
if ($Code -ne 0) {
    Fenetre "Un réglage de sécurité n'est pas bon : le bac à sable n'a PAS été lancé.`n`nOuvre journal.txt dans $Racine pour voir le détail, ou double-clique sur `"Mettre a jour.bat`"." 'OK' 'Error' | Out-Null
    exit 2
}

# 3. Windows à jour ? Les failles qui permettraient à un virus de SORTIR du bac à sable
#    sont corrigées par Windows Update : sans mises à jour récentes, on bloque
#    (lancement seulement si l'utilisateur insiste ; bouton par défaut = Non).
$DerniereMaj = $null
try { $DerniereMaj = (Get-HotFix -ErrorAction Stop | Where-Object InstalledOn | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn } catch { }
if ($DerniereMaj -and ((Get-Date) - $DerniereMaj).TotalDays -gt 45) {
    $jours = [int]((Get-Date) - $DerniereMaj).TotalDays
    $rep = Fenetre ("DANGER : Windows n'a pas été mis à jour depuis $jours jours.`n`n" +
        "Les mises à jour corrigent les failles qui permettraient à un virus de sortir du bac à sable.`n`n" +
        "Fais d'abord : Paramètres > Windows Update > Rechercher des mises à jour, puis redémarre.`n`n" +
        "Lancer quand même (déconseillé) ?") 'YesNo' 'Error' 'Button2'
    if ($rep -ne 'Yes') { exit 3 }
}

# 3 bis. Mode Famille : VirtualBox à jour ? (mêmes raisons : ses failles sont corrigées par ses mises à jour)
if ($Mode -eq 'VirtualBox') {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $derniere = [version]((Invoke-WebRequest 'https://download.virtualbox.org/virtualbox/LATEST.TXT' -UseBasicParsing -TimeoutSec 6).Content.Trim())
        $installee = Version-VBox $VBoxManage
        if ($installee -and $installee -lt $derniere) {
            $rep = Fenetre ("VirtualBox n'est pas à jour (tu as $installee, la dernière est $derniere).`n`n" +
                "Les mises à jour de VirtualBox corrigent les failles qui permettraient à un virus de sortir de la machine.`n`n" +
                "Mettre à jour maintenant ? (recommandé, quelques minutes, tout est automatique)") 'YesNo' 'Warning'
            if ($rep -eq 'Yes') {
                Start-Process powershell -Wait -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $Racine 'installer.ps1')`" -MajVirtualBox"
                $installee = Version-VBox $VBoxManage
            }
            if (-not $installee -or $installee -lt $derniere) {
                $rep = Fenetre ("DANGER : VirtualBox n'est toujours pas à jour.`n`nLancer quand même (déconseillé) ?") 'YesNo' 'Error' 'Button2'
                if ($rep -ne 'Yes') { exit 3 }
            }
        }
    } catch { }   # pas d'internet : on ne bloque pas
}

# 4. Avertissement pour la version internet
if ($Profil -eq 'Internet') {
    $rep = Fenetre "ATTENTION : internet sera ACTIF dans le bac à sable.`n`nNe te connecte JAMAIS à un vrai compte (Discord, mail, Steam, banque…) dans cette fenêtre.`n`nPour tester un fichier, préfère `"Bac à sable (sécurisé)`".`n`nContinuer ?" 'YesNo' 'Warning'
    if ($rep -ne 'Yes') { exit 0 }
}

# 5a. Windows Sandbox
if ($Mode -eq 'Sandbox') {
    Start-Process -FilePath (Join-Path $Racine "Sandbox_$Profil.wsb")
    exit 0
}

# 5b. Mode Famille : VirtualBox
function Etat-VM {
    $l = & $VBoxManage showvminfo $NomVM --machinereadable 2>$null | Select-String '^VMState="(.+)"'
    if ($l) { return $l.Matches[0].Groups[1].Value } else { return 'absente' }
}
if ((Etat-VM) -notin 'poweroff', 'aborted', 'saved') {
    Fenetre 'Le bac à sable est déjà ouvert (une seule fenêtre à la fois).' | Out-Null
    exit 0
}
# Retour à l'état propre (efface tout ce qui a pu se passer avant).
& $VBoxManage snapshot $NomVM restore propre 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Fenetre "Impossible de remettre la machine à son état propre : le bac à sable n'a PAS été lancé.`n`nRelance Installer.bat pour la réparer." 'OK' 'Error' | Out-Null
    exit 4
}
if ($Profil -eq 'Internet') { & $VBoxManage modifyvm $NomVM --nic1 nat 2>$null | Out-Null }

$problemes = Verifier-VM (& $VBoxManage showvminfo $NomVM --machinereadable) ((& $VBoxManage showvminfo $NomVM) -join "`n") $Profil $ATester
if ($problemes.Count -gt 0) {
    Fenetre ("Un réglage de sécurité de la machine n'est pas bon : le bac à sable n'a PAS été lancé.`n`n- " + ($problemes -join "`n- ") +
        "`n`nRelance Installer.bat pour recréer la machine.") 'OK' 'Error' | Out-Null
    exit 5
}

& $VBoxManage startvm $NomVM --type gui 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Fenetre "VirtualBox n'a pas pu démarrer la machine.`n`nRedémarre le PC et réessaie. Si ça recommence, relance Installer.bat." 'OK' 'Error' | Out-Null
    exit 6
}

# Attend la fermeture, puis EFFACE tout (retour à l'état propre).
Start-Sleep -Seconds 10
while ((Etat-VM) -notin 'poweroff', 'aborted', 'saved', 'absente') { Start-Sleep -Seconds 5 }
& $VBoxManage snapshot $NomVM restore propre 2>$null | Out-Null

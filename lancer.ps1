# ====================================================================
#  Lance le bac à sable (utilisé par les raccourcis du bureau).
#  Avant chaque lancement :
#    1. propose la nouvelle version du kit si elle existe (GitHub) ;
#    2. recrée les fichiers .wsb et vérifie leurs réglages de sécurité ;
#    3. refuse de lancer si un réglage n'est pas sûr.
# ====================================================================
param([ValidateSet('Securise', 'Internet')][string]$Profil = 'Securise')

$Racine = $PSScriptRoot
Add-Type -AssemblyName System.Windows.Forms

function Fenetre([string]$texte, [string]$boutons = 'OK', [string]$icone = 'Information') {
    [System.Windows.Forms.MessageBox]::Show($texte, 'Bac à sable', $boutons, $icone)
}

if (-not (Test-Path (Join-Path $env:WINDIR 'System32\WindowsSandbox.exe'))) {
    Fenetre "Windows Sandbox n'est pas activé sur ce PC.`n`nDouble-clique sur Installer.bat (dans $Racine), clique Oui, puis redémarre." 'OK' 'Warning' | Out-Null
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

# 3. Avertissement pour la version internet
if ($Profil -eq 'Internet') {
    $rep = Fenetre "ATTENTION : internet sera ACTIF dans le bac à sable.`n`nNe te connecte JAMAIS à un vrai compte (Discord, mail, Steam, banque…) dans cette fenêtre.`n`nPour tester un fichier, préfère `"Bac à sable (sécurisé)`".`n`nContinuer ?" 'YesNo' 'Warning'
    if ($rep -ne 'Yes') { exit 0 }
}

$Wsb = Join-Path $Racine "Sandbox_$Profil.wsb"
Start-Process -FilePath $Wsb

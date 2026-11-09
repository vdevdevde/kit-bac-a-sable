# ====================================================================
#  Mise à jour automatique du kit depuis GitHub
#  - regarde la dernière version publiée (GitHub Releases) ;
#  - si elle est plus récente, DEMANDE l'accord (fenêtre Oui / Non) ;
#  - remplace UNIQUEMENT les fichiers du kit (liste ci-dessous) :
#    A_tester, interdits.txt, journal.txt ne sont jamais touchés ;
#  - garde l'ancienne version dans _sauvegardes\.
#  Renvoie $true si une mise à jour a été installée, sinon $false.
#  -Silencieux : aucun message si tout est à jour ou sans internet.
# ====================================================================
param([switch]$Silencieux)

$Depot  = 'vdevdevde/bac-a-sable-windows'
$Racine = $PSScriptRoot
$FichiersDuKit = @(
    'mettre_a_jour.ps1', 'Mettre a jour.bat', 'maj_auto.ps1', 'lancer.ps1',
    'installer.ps1', 'Installer.bat', 'Activer le bac a sable.bat', 'README.md'
)

function Dire([string]$t) {
    if (-not $Silencieux) { Write-Host $t }
    $ligne = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  [maj] ' + $t
    Add-Content -Path (Join-Path $Racine 'journal.txt') -Value $ligne -Encoding UTF8 -ErrorAction SilentlyContinue
}

# --- Version installée (lue dans mettre_a_jour.ps1)
$texte = Get-Content (Join-Path $Racine 'mettre_a_jour.ps1') -Raw -Encoding UTF8
if ($texte -notmatch "\`$VersionKit = '([0-9.]+)'") { Dire 'Version locale introuvable.'; return $false }
$Locale = [version]$Matches[1]

# --- Dernière version publiée sur GitHub
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$Depot/releases/latest" `
        -Headers @{ 'User-Agent' = 'BacASable-maj' } -TimeoutSec 6 -UseBasicParsing
    $Distante = [version]($rel.tag_name.TrimStart('v'))
} catch {
    if (-not $Silencieux) { Write-Host "Mise à jour : impossible de vérifier (pas d'internet, ou aucune version publiée). On continue." }
    return $false
}
if ($Distante -le $Locale) { if (-not $Silencieux) { Write-Host "Mise à jour : le kit est à jour ($Locale)." }; return $false }

$Zip = $rel.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
if (-not $Zip) { Dire "Version $Distante trouvée mais sans fichier .zip : ignorée."; return $false }

# --- Demande l'accord
Add-Type -AssemblyName System.Windows.Forms
$notes = "$($rel.body)".Trim()
if ($notes.Length -gt 600) { $notes = $notes.Substring(0, 600) + '…' }
$message = "Une nouvelle version du Bac à sable est disponible.`n`n" +
           "Ta version : $Locale`nNouvelle version : $Distante`n`nNouveautés :`n$notes`n`n" +
           "Source : github.com/$Depot`n`nL'installer maintenant ?"
$rep = [System.Windows.Forms.MessageBox]::Show($message, 'Mise à jour du Bac à sable', 'YesNo', 'Question')
if ($rep -ne 'Yes') { Dire "Version $Distante proposée, refusée."; return $false }

# --- Télécharge, vérifie, installe
$Temp = Join-Path $env:TEMP ("BacASable_maj_" + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $Temp | Out-Null
    $fichierZip = Join-Path $Temp 'kit.zip'
    Invoke-WebRequest -Uri $Zip.browser_download_url -OutFile $fichierZip -UseBasicParsing -TimeoutSec 60
    if ((Get-Item $fichierZip).Length -ne $Zip.size) { throw 'taille du téléchargement incorrecte' }
    $Extrait = Join-Path $Temp 'kit'
    Expand-Archive -Path $fichierZip -DestinationPath $Extrait -Force

    $nouveaux = @{}
    Get-ChildItem $Extrait -Recurse -File | ForEach-Object {
        if ($FichiersDuKit -contains $_.Name) { $nouveaux[$_.Name] = $_.FullName }
    }
    if (-not $nouveaux.ContainsKey('mettre_a_jour.ps1')) { throw 'le .zip ne contient pas mettre_a_jour.ps1' }

    $Sauv = Join-Path $Racine '_sauvegardes'
    if (-not (Test-Path $Sauv)) { New-Item -ItemType Directory -Path $Sauv | Out-Null }
    $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    foreach ($nom in $nouveaux.Keys) {
        $cible = Join-Path $Racine $nom
        if (Test-Path $cible) { Copy-Item $cible (Join-Path $Sauv "$nom.v$Locale.$stamp") }
        Copy-Item $nouveaux[$nom] $cible -Force
    }
    Dire "Mise à jour installée : $Locale -> $Distante ($($nouveaux.Count) fichiers)."
    return $true
} catch {
    Dire "Mise à jour ÉCHOUÉE ($($_.Exception.Message)). L'ancienne version reste en place."
    [System.Windows.Forms.MessageBox]::Show("La mise à jour a échoué : $($_.Exception.Message)`n`nL'ancienne version reste en place.", 'Mise à jour du Bac à sable', 'OK', 'Warning') | Out-Null
    return $false
} finally {
    Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
}

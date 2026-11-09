# 🧪 Bac à sable Windows : kit sécurisé

Teste un fichier douteux (un `.exe` reçu sur Discord, un « crack », un logiciel inconnu…) dans un **Windows jetable**, sans risque pour ton vrai PC. Quand tu fermes la fenêtre, **tout est effacé**.

Le kit se **met à jour tout seul** : à chaque ouverture, il te propose la nouvelle version si elle existe.

---

## ✅ Il te faut

- **N'importe quel Windows 10 ou 11**, Famille compris :
  - **Pro, Entreprise, Éducation** : le kit utilise **Windows Sandbox**, intégré à Windows.
  - **Famille (Home)** : le kit utilise le **mode Famille**, un Windows jetable dans **VirtualBox** (gratuit). L'installeur **installe VirtualBox tout seul** (site officiel, fichier vérifié). Il t'ouvre aussi la page de Microsoft pour télécharger l'image Windows 11 d'évaluation gratuite (un formulaire à remplir), la retrouve tout seul dans tes Téléchargements, puis prépare la machine (30 à 90 minutes, une seule fois). 🧪 *Mode encore en test.*
- La **virtualisation activée** dans le BIOS (c'est le cas sur la plupart des PC récents ; l'installeur vérifie).
- Mode Famille : 8 Go de mémoire et 40 Go libres sur C:.

## 📥 Installer (5 minutes)

1. En haut de cette page, clique sur **Releases** (à droite), puis sur **`BacASable-x.y.z.zip`** pour le télécharger.
2. Fais un clic droit sur le `.zip` → **Extraire tout…**. Choisis un endroit où le dossier restera, par exemple `Documents\BacASable`.
3. Dans le dossier extrait, double-clique sur **`Installer.bat`**.
   - Si Windows affiche « Windows a protégé votre ordinateur », clique sur **Informations complémentaires** → **Exécuter quand même**. Ne fais ça que pour un fichier venant de cette page.
   - Quand Windows demande « Autoriser cette application ? », clique sur **Oui**.
4. **Redémarre** le PC.

Trois raccourcis apparaissent sur ton bureau : **Bac à sable (sécurisé)**, **Bac à sable (internet)** et **Fichiers à tester**.

## 🕹️ Utiliser (à chaque fois)

1. **Passe d'abord le fichier sur [virustotal.com](https://www.virustotal.com).** Si plusieurs antivirus le signalent, supprime-le et arrête-toi là.
2. Mets le fichier dans **Fichiers à tester** (le raccourci du bureau). ⚠️ Ne le lance **pas** là : tu es encore sur ton vrai PC.
3. Double-clique sur **Bac à sable (sécurisé)** et attends qu'un Windows apparaisse dans la fenêtre (30 s à 1 min).
4. **Dans cette fenêtre**, ouvre le dossier **A_tester** de son bureau et lance le fichier.
5. Ferme la fenêtre : tout est effacé. Vide ensuite **Fichiers à tester**.

Mode d'emploi complet : `LISEZ-MOI.txt`, créé par l'installeur dans le dossier du kit.

---

## 🔒 Ce qui te protège

| Réglage | Sécurisé | Internet |
|---|---|---|
| Internet | ❌ coupé | ✅ actif |
| Dossier `A_tester` | lecture seule | lecture seule |
| Copier-coller avec ton PC | ❌ coupé | ❌ coupé |
| Micro, webcam, imprimante, carte graphique | ❌ coupés | ❌ coupés |
| Programme lancé automatiquement | aucun | aucun |

- Avant **chaque** lancement, les réglages sont **recréés et vérifiés**. Si l'un d'eux n'est pas sûr, le bac à sable ne s'ouvre pas.
- **Mode Famille** : la machine revient à son état propre avant et après chaque utilisation. Mêmes réglages : pas de réseau, copier-coller, glisser-déposer, son, USB et bureau à distance coupés, `A_tester` en lecture seule.
- **Windows et VirtualBox doivent être à jour**, car ces mises à jour corrigent les failles qui permettraient à un virus de sortir. Si VirtualBox est en retard, le raccourci propose de le mettre à jour tout seul. Si Windows est en retard, il refuse de lancer (sauf si tu insistes).
- **Mise à jour automatique avec ton accord** : le kit vérifie GitHub, mais n'installe rien sans que tu cliques **Oui**. Il remplace seulement ses propres fichiers, et l'ancienne version est gardée dans `_sauvegardes\`.
- **Bilan de sécurité** : `Mettre a jour.bat` vérifie ton antivirus, ton pare-feu, l'UAC, l'isolation matérielle et les mises à jour Windows, **sans rien modifier**.

## ⚠️ Les limites (à lire)

- **Rien n'est sûr à 100 %.** De très rares failles permettant de « sortir » d'une machine virtuelle ont existé. Garde **Windows à jour**.
- **Un virus peut « faire le mort »** dans un bac à sable. « Rien ne se passe » ne veut **pas** dire « fichier sain ».
- **Ne tape jamais un vrai mot de passe** dans le bac à sable (Discord, mail, Steam, banque…).
- N'utilise la version **internet** que si un installeur doit vraiment télécharger quelque chose.
- Ne désactive **jamais** ton antivirus, le pare-feu ou l'UAC pour « faire marcher » un programme.

---

## 🛠️ Fichiers du kit

| Fichier | Rôle |
|---|---|
| `Installer.bat` / `installer.ps1` | Vérifie le PC, crée le kit et les raccourcis, active Windows Sandbox |
| `lancer.ps1` | Utilisé par les raccourcis : mise à jour, vérification de sécurité, lancement |
| `Mettre a jour.bat` / `mettre_a_jour.ps1` | Recrée et répare les fichiers, fait le bilan de sécurité du PC |
| `maj_auto.ps1` | Cherche une nouvelle version sur GitHub et l'installe avec ton accord |
| `Activer le bac a sable.bat` | Active Windows Sandbox (demande les droits administrateur) |
| `publier.ps1` / `Publier une version.bat` | Pour le propriétaire du dépôt : publier une nouvelle version |

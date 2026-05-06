# S3 Client Lite / R2Desk

**Langues :** [English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md) | [বাংলা](README.bn.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Français](README.fr.md)

Client macOS natif pour le stockage d'objets compatible S3, conçu surtout pour la gestion quotidienne de fichiers sur Cloudflare R2.

![Bucket Browser](screens/01-bucket-browser.png)

## Télécharger et lancer

### Depuis GitHub Actions

Chaque push exécute le workflow de build macOS et publie des artefacts prêts à utiliser :

- `R2Desk-macOS.zip`
- `R2Desk-macOS.dmg`

Ouvrez l'onglet **Actions** du dépôt, choisissez la dernière exécution réussie de **Build macOS App**, puis téléchargez l'artefact `R2Desk-macOS`.

### Build local

```bash
swift test
swift build
bash scripts/package_app.sh
```

Les fichiers empaquetés sont générés ici :

- `dist/R2Desk-macOS.zip`
- `dist/R2Desk-macOS.dmg`

### Ouvrir sans certificat Apple Developer

L'app est signée en ad-hoc, elle ne nécessite donc pas de certificat Apple Developer payant. Si macOS bloque l'app téléchargée, faites un clic droit sur **R2Desk.app** et choisissez **Open** une fois.

Si nécessaire :

```bash
xattr -dr com.apple.quarantine /Applications/R2Desk.app
```

## Fonctionnalités

### Stockage et buckets

- Prise en charge de Cloudflare R2 et des endpoints compatibles S3
- Gestion de plusieurs buckets
- Buckets favoris et récents
- Modèle d'endpoint Cloudflare R2
- Test de connexion avant ou après l'enregistrement d'un bucket
- Configuration locale dans `Application Support/R2Desk/config.json`
- Clés secrètes stockées dans macOS Keychain
- Import/export de configuration sans exporter les secrets du Keychain

### Opérations sur les fichiers

- Lister les objets par bucket et prefix
- Navigation de type dossier via les prefixes S3
- Créer des dossiers
- Rechercher/filtrer dans le chemin actuel
- Upload par glisser-déposer
- Progression d'upload, annulation et nouvelle tentative des uploads échoués
- Détection automatique du Content-Type à l'upload
- Gestion des conflits d'upload : remplacer ou renommer automatiquement
- Supprimer un objet ou supprimer en lot les objets sélectionnés
- Télécharger un objet ou télécharger en lot les objets sélectionnés
- Ouvrir l'objet téléchargé avec l'app système par défaut
- Renommer/déplacer un objet avec S3 copy + delete
- Copier l'object key
- Copier l'URL directe S3/R2
- Générer et copier un lien de téléchargement presigned valable une heure

### Visibilité et productivité

- Détails d'objet : key, taille, date de modification, storage class, ETag, Content-Type, metadata
- Résumé d'utilisation du bucket
- Historique local des opérations
- Notifications macOS après upload/download/delete
- Raccourcis clavier pour actualiser, envoyer, télécharger, supprimer, ouvrir et créer un dossier
- Texte d'interface en anglais et en chinois
- Build et packaging GitHub CI

## Configuration Cloudflare R2

Lors de l'ajout d'un bucket, utilisez :

- Endpoint : `https://<account-id>.r2.cloudflarestorage.com`
- Region : `auto`
- Bucket Name : le nom de votre bucket R2
- Access Key ID : l'access key de votre token API R2
- Secret Access Key : le secret de votre token API R2

Permissions recommandées pour le token R2 :

- Object Read
- Object Write

La suppression nécessite aussi une permission delete.

## Captures d'écran

![Bucket Browser](screens/01-bucket-browser.png)
![Add Bucket](screens/02-add-bucket.png)
![Upload Flow](screens/03-upload-flow.png)
![Open File](screens/04-open-file.png)
![Delete Confirmation](screens/05-delete-confirmation.png)
![Bucket Settings](screens/06-bucket-settings.png)
![Folder Browsing](screens/07-folder-browsing.png)
![Search Filter](screens/08-search-filter.png)
![Presigned Link](screens/09-presigned-link.png)
![Rename And Move](screens/10-rename-move.png)
![Details Panel](screens/11-details-panel.png)
![Batch Selection](screens/12-batch-selection.png)
![Favorites And Recent](screens/13-favorites-recent.png)
![Upload Conflict](screens/14-upload-conflict.png)
![Operation History](screens/15-operation-history.png)

## Raccourcis clavier

| Action | Raccourci |
| --- | --- |
| Actualiser | `⌘R` |
| Envoyer | `⌘U` |
| Télécharger | `⌘D` |
| Nouveau dossier | `⇧⌘N` |
| Ouvrir | `Return` |
| Supprimer | `Delete` |

## Données locales

R2Desk conserve toutes les données utilisateur sur le Mac local :

- Configuration publique des buckets : `~/Library/Application Support/R2Desk/config.json`
- Secrets d'accès : macOS Keychain
- Fichiers ouverts temporairement : dossier temporaire du système

L'export de configuration n'inclut pas les clés secrètes.

## Développement

```bash
swift test
swift build
bash scripts/package_app.sh
```

Workflow CI :

- [`.github/workflows/build-macos.yml`](.github/workflows/build-macos.yml)

Script de packaging :

- [`scripts/package_app.sh`](scripts/package_app.sh)

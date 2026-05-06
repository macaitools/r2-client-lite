# S3 Client Lite / R2Desk

**Languages:** [English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md) | [বাংলা](README.bn.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Français](README.fr.md)

Native macOS client for S3-compatible object storage, designed especially for daily Cloudflare R2 file management.

![Bucket Browser](screens/01-bucket-browser.png)

## Download And Run

### Latest Release

Download the latest macOS package from [GitHub Releases](https://github.com/macaitools/s3-client-lite/releases/latest).

Release builds include:

- `R2Desk-macOS.zip`
- `R2Desk-macOS.dmg`

### From GitHub Actions

Every push runs the macOS build workflow and uploads ready-to-run artifacts:

- `R2Desk-macOS.zip`
- `R2Desk-macOS.dmg`

Open the repository **Actions** tab, choose the latest successful **Build macOS App** run, then download the `R2Desk-macOS` artifact.

### Build Locally

```bash
swift test
swift build
bash scripts/package_app.sh
```

Packaged files are generated here:

- `dist/R2Desk-macOS.zip`
- `dist/R2Desk-macOS.dmg`

### Open Without An Apple Developer Certificate

The app is ad-hoc signed, so it does not require a paid Apple Developer certificate. If macOS blocks the downloaded app, right-click **R2Desk.app** and choose **Open** once.

If needed:

```bash
xattr -dr com.apple.quarantine /Applications/R2Desk.app
```

## Features

### Storage And Buckets

- Cloudflare R2 and S3-compatible endpoint support
- Multi-bucket management
- Favorite buckets and recent buckets
- Cloudflare R2 endpoint template
- Connection testing before or after saving a bucket
- Local config stored at `Application Support/R2Desk/config.json`
- Secret keys stored in macOS Keychain
- Config import/export without exporting Keychain secrets

### File Operations

- List objects by bucket and prefix
- Folder-like browsing through S3 prefixes
- Create folders
- Search/filter within the current path
- Drag-and-drop upload
- Upload progress, cancel, and retry failed uploads
- Upload Content-Type auto detection
- Upload conflict handling: replace or auto rename
- Delete one object or batch delete selected objects
- Download one object or batch download selected objects
- Open downloaded object with the system default app
- Rename/move object using S3 copy + delete
- Copy object key
- Copy direct S3/R2 object URL
- Generate and copy a one-hour presigned download link

### Visibility And Productivity

- Object details: key, size, modified time, storage class, ETag, Content-Type, metadata
- Bucket usage summary
- Local operation history
- macOS notifications for completed upload/download/delete operations
- Keyboard shortcuts for refresh, upload, download, delete, open, and new folder
- English and Chinese interface text
- GitHub CI build and packaging

## Cloudflare R2 Setup

When adding a bucket, use:

- Endpoint: `https://<account-id>.r2.cloudflarestorage.com`
- Region: `auto`
- Bucket Name: your R2 bucket name
- Access Key ID: your R2 API token access key
- Secret Access Key: your R2 API token secret

Recommended R2 token permissions:

- Object Read
- Object Write

Delete support requires delete permission.

## Screenshots

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

## Keyboard Shortcuts

| Action | Shortcut |
| --- | --- |
| Refresh | `⌘R` |
| Upload | `⌘U` |
| Download | `⌘D` |
| New Folder | `⇧⌘N` |
| Open | `Return` |
| Delete | `Delete` |

## Local Data

R2Desk keeps all user data on the local Mac:

- Public bucket config: `~/Library/Application Support/R2Desk/config.json`
- Access secrets: macOS Keychain
- Temporary opened files: system temporary directory

Config export does not include secret keys.

## Development

```bash
swift test
swift build
bash scripts/package_app.sh
```

CI workflow:

- [`.github/workflows/build-macos.yml`](.github/workflows/build-macos.yml)

Packaging script:

- [`scripts/package_app.sh`](scripts/package_app.sh)

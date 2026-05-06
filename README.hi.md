# S3 Client Lite / R2Desk

**भाषाएं:** [English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md) | [বাংলা](README.bn.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Français](README.fr.md)

S3-compatible object storage के लिए native macOS client, खास तौर पर Cloudflare R2 में रोजमर्रा की file management के लिए बनाया गया।

![Bucket Browser](screens/01-bucket-browser.png)

## डाउनलोड और चलाएं

### GitHub Actions से

हर push macOS build workflow चलाता है और चलाने योग्य artifacts अपलोड करता है:

- `R2Desk-macOS.zip`
- `R2Desk-macOS.dmg`

Repository के **Actions** tab में जाएं, **Build macOS App** की latest successful run चुनें, फिर `R2Desk-macOS` artifact डाउनलोड करें।

### Local build

```bash
swift test
swift build
bash scripts/package_app.sh
```

Packaged files यहां बनती हैं:

- `dist/R2Desk-macOS.zip`
- `dist/R2Desk-macOS.dmg`

### Apple Developer certificate के बिना खोलें

App ad-hoc signed है, इसलिए paid Apple Developer certificate की जरूरत नहीं है। अगर macOS downloaded app को block करे, तो **R2Desk.app** पर right-click करके एक बार **Open** चुनें।

जरूरत होने पर:

```bash
xattr -dr com.apple.quarantine /Applications/R2Desk.app
```

## Features

### Storage और buckets

- Cloudflare R2 और S3-compatible endpoints का support
- Multiple buckets manage करना
- Favorite buckets और recent buckets
- Cloudflare R2 endpoint template
- Bucket save करने से पहले या बाद में connection test
- Local config: `Application Support/R2Desk/config.json`
- Secret keys macOS Keychain में save होती हैं
- Config import/export, लेकिन Keychain secrets export नहीं होते

### File operations

- Bucket और prefix के हिसाब से objects list करना
- S3 prefixes से folder-like browsing
- Folders बनाना
- Current path में search/filter
- Drag-and-drop upload
- Upload progress, cancel, और failed uploads retry
- Upload Content-Type की automatic detection
- Upload conflict handling: replace या auto rename
- Single object delete या selected objects batch delete
- Single object download या selected objects batch download
- Downloaded object को system default app से खोलना
- S3 copy + delete से object rename/move
- Object key copy करना
- Direct S3/R2 object URL copy करना
- One-hour presigned download link generate और copy करना

### Visibility और productivity

- Object details: key, size, modified time, storage class, ETag, Content-Type, metadata
- Bucket usage summary
- Local operation history
- Upload/download/delete पूरा होने पर macOS notifications
- Refresh, upload, download, delete, open, और new folder के keyboard shortcuts
- English और Chinese interface text
- GitHub CI build और packaging

## Cloudflare R2 setup

Bucket जोड़ते समय यह भरें:

- Endpoint: `https://<account-id>.r2.cloudflarestorage.com`
- Region: `auto`
- Bucket Name: आपका R2 bucket name
- Access Key ID: आपके R2 API token की access key
- Secret Access Key: आपके R2 API token का secret

Recommended R2 token permissions:

- Object Read
- Object Write

Delete support के लिए delete permission भी चाहिए।

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

## Keyboard shortcuts

| Action | Shortcut |
| --- | --- |
| Refresh | `⌘R` |
| Upload | `⌘U` |
| Download | `⌘D` |
| New Folder | `⇧⌘N` |
| Open | `Return` |
| Delete | `Delete` |

## Local data

R2Desk सभी user data local Mac पर रखता है:

- Public bucket config: `~/Library/Application Support/R2Desk/config.json`
- Access secrets: macOS Keychain
- Temporary opened files: system temporary directory

Config export में secret keys शामिल नहीं होतीं।

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

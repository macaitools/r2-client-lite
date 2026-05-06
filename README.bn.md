# S3 Client Lite / R2Desk

**ভাষা:** [English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md) | [বাংলা](README.bn.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Français](README.fr.md)

S3-compatible object storage-এর জন্য native macOS client, বিশেষ করে Cloudflare R2-তে দৈনন্দিন file management-এর জন্য তৈরি।

![Bucket Browser](screens/01-bucket-browser.png)

## ডাউনলোড ও চালানো

### GitHub Actions থেকে

প্রতিটি push macOS build workflow চালায় এবং ready-to-run artifacts আপলোড করে:

- `R2Desk-macOS.zip`
- `R2Desk-macOS.dmg`

Repository-এর **Actions** tab খুলুন, **Build macOS App**-এর সর্বশেষ successful run নির্বাচন করুন, তারপর `R2Desk-macOS` artifact ডাউনলোড করুন।

### লোকালি build

```bash
swift test
swift build
bash scripts/package_app.sh
```

Packaged files এখানে তৈরি হয়:

- `dist/R2Desk-macOS.zip`
- `dist/R2Desk-macOS.dmg`

### Apple Developer certificate ছাড়া খুলুন

App টি ad-hoc signed, তাই paid Apple Developer certificate দরকার নেই। macOS downloaded app block করলে, **R2Desk.app**-এ right-click করে একবার **Open** বেছে নিন।

প্রয়োজনে:

```bash
xattr -dr com.apple.quarantine /Applications/R2Desk.app
```

## Features

### Storage ও buckets

- Cloudflare R2 এবং S3-compatible endpoints support
- একাধিক bucket manage করা
- Favorite buckets ও recent buckets
- Cloudflare R2 endpoint template
- Bucket save করার আগে বা পরে connection test
- Local config: `Application Support/R2Desk/config.json`
- Secret keys macOS Keychain-এ রাখা হয়
- Config import/export, কিন্তু Keychain secrets export হয় না

### File operations

- Bucket ও prefix অনুযায়ী objects list করা
- S3 prefixes দিয়ে folder-like browsing
- Folder তৈরি করা
- Current path-এ search/filter
- Drag-and-drop upload
- Upload progress, cancel, এবং failed uploads retry
- Upload Content-Type auto detection
- Upload conflict handling: replace বা auto rename
- একটি object delete বা selected objects batch delete
- একটি object download বা selected objects batch download
- Downloaded object system default app দিয়ে খোলা
- S3 copy + delete দিয়ে object rename/move
- Object key copy করা
- Direct S3/R2 object URL copy করা
- এক ঘণ্টার presigned download link generate ও copy করা

### Visibility ও productivity

- Object details: key, size, modified time, storage class, ETag, Content-Type, metadata
- Bucket usage summary
- Local operation history
- Upload/download/delete শেষ হলে macOS notifications
- Refresh, upload, download, delete, open, এবং new folder-এর keyboard shortcuts
- English ও Chinese interface text
- GitHub CI build ও packaging

## Cloudflare R2 setup

Bucket যোগ করার সময় ব্যবহার করুন:

- Endpoint: `https://<account-id>.r2.cloudflarestorage.com`
- Region: `auto`
- Bucket Name: আপনার R2 bucket name
- Access Key ID: আপনার R2 API token access key
- Secret Access Key: আপনার R2 API token secret

Recommended R2 token permissions:

- Object Read
- Object Write

Delete support-এর জন্য delete permission-ও দরকার।

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

R2Desk সব user data local Mac-এ রাখে:

- Public bucket config: `~/Library/Application Support/R2Desk/config.json`
- Access secrets: macOS Keychain
- Temporary opened files: system temporary directory

Config export-এ secret keys থাকে না।

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

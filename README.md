# S3 Client Lite / R2Desk

Native macOS client for S3-compatible object storage, designed especially for Cloudflare R2.

原生 macOS S3/R2 文件管理客户端，主打 Cloudflare R2 日常文件管理：多 Bucket、本地保存配置、钥匙串保存密钥、快速上传、删除、下载和系统打开。

![Bucket Browser](screens/01-bucket-browser.png)

## Download And Run / 下载运行

### From GitHub Actions / 从 GitHub Actions 获取

Every push runs the macOS build workflow and uploads ready-to-run artifacts:

每次推送都会通过 GitHub Actions 自动构建，并上传可运行产物：

- `R2Desk-macOS.zip`
- `R2Desk-macOS.dmg`

Open the repository **Actions** tab, choose the latest successful **Build macOS App** run, then download the `R2Desk-macOS` artifact.

打开仓库的 **Actions** 页面，选择最新成功的 **Build macOS App**，下载 `R2Desk-macOS` 产物即可。

### Build Locally / 本地构建

```bash
swift test
swift build
bash scripts/package_app.sh
```

Packaged files are generated here:

打包完成后，可直接运行的文件会生成在：

- `dist/R2Desk-macOS.zip`
- `dist/R2Desk-macOS.dmg`

### Open Without Apple Developer Certificate / 无开发者证书打开

The app is ad-hoc signed, so it does not require a paid Apple Developer certificate. If macOS blocks the downloaded app, right-click **R2Desk.app** and choose **Open** once.

应用使用 ad-hoc 签名，不需要付费 Apple Developer 证书。如果 macOS 阻止打开，右键 **R2Desk.app**，选择 **打开** 一次即可。

If needed:

如仍被拦截，可执行：

```bash
xattr -dr com.apple.quarantine /Applications/R2Desk.app
```

## Feature List / 功能清单

### Storage And Buckets / 存储与 Bucket

- Cloudflare R2 and S3-compatible endpoint support
- Multi-bucket management
- Favorite buckets and recent buckets
- Cloudflare R2 endpoint template
- Connection testing before or after saving a bucket
- Local config stored at `Application Support/R2Desk/config.json`
- Secret keys stored in macOS Keychain
- Config import/export without exporting Keychain secrets

### File Operations / 文件操作

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
- Generate and copy one-hour presigned download link

### Visibility And Productivity / 可见性与效率

- Object details: key, size, modified time, storage class, ETag, Content-Type, metadata
- Bucket usage summary
- Local operation history
- macOS notifications for completed upload/download/delete operations
- Keyboard shortcuts for refresh, upload, download, delete, open, and new folder
- English and Chinese interface text
- GitHub CI build and packaging

## Cloudflare R2 Setup / Cloudflare R2 配置

When adding a bucket, use:

添加 Bucket 时填写：

- Endpoint: `https://<account-id>.r2.cloudflarestorage.com`
- Region: `auto`
- Bucket Name: your R2 bucket name
- Access Key ID: your R2 API token access key
- Secret Access Key: your R2 API token secret

Recommended R2 token permissions:

建议 R2 Token 权限：

- Object Read
- Object Write

Delete support requires delete permission.

如果需要删除文件，Token 也需要删除权限。

## Screenshots / 界面截图

### Bucket Browser / Bucket 浏览

![Bucket Browser](screens/01-bucket-browser.png)

### Add Bucket / 添加 Bucket

![Add Bucket](screens/02-add-bucket.png)

### Upload Flow / 上传流程

![Upload Flow](screens/03-upload-flow.png)

### Open File / 系统打开文件

![Open File](screens/04-open-file.png)

### Delete Confirmation / 删除确认

![Delete Confirmation](screens/05-delete-confirmation.png)

### Bucket Settings / Bucket 设置

![Bucket Settings](screens/06-bucket-settings.png)

### Folder Browsing / 文件夹浏览

![Folder Browsing](screens/07-folder-browsing.png)

### Search Filter / 搜索过滤

![Search Filter](screens/08-search-filter.png)

### Presigned Link / 预签名链接

![Presigned Link](screens/09-presigned-link.png)

### Rename And Move / 重命名与移动

![Rename And Move](screens/10-rename-move.png)

### Details Panel / 文件详情

![Details Panel](screens/11-details-panel.png)

### Batch Selection / 批量选择

![Batch Selection](screens/12-batch-selection.png)

### Favorites And Recent / 收藏与最近

![Favorites And Recent](screens/13-favorites-recent.png)

### Upload Conflict / 上传冲突处理

![Upload Conflict](screens/14-upload-conflict.png)

### Operation History / 操作记录

![Operation History](screens/15-operation-history.png)

## Keyboard Shortcuts / 快捷键

| Action | Shortcut |
| --- | --- |
| Refresh / 刷新 | `⌘R` |
| Upload / 上传 | `⌘U` |
| Download / 下载 | `⌘D` |
| New Folder / 新建文件夹 | `⇧⌘N` |
| Open / 打开 | `Return` |
| Delete / 删除 | `Delete` |

## Local Data / 本地数据

R2Desk keeps all user data on the local Mac.

R2Desk 的用户数据全部保存在本机：

- Public bucket config: `~/Library/Application Support/R2Desk/config.json`
- Access secrets: macOS Keychain
- Temporary opened files: system temporary directory

Config export does not include secret keys.

配置导出不会包含 Secret Access Key。

## Development / 开发

```bash
swift test
swift build
bash scripts/package_app.sh
```

CI workflow:

CI 工作流：

- [`.github/workflows/build-macos.yml`](.github/workflows/build-macos.yml)

Packaging script:

打包脚本：

- [`scripts/package_app.sh`](scripts/package_app.sh)

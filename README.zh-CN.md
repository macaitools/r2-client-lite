# S3 Client Lite / R2Desk

**语言：** [English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md) | [বাংলা](README.bn.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Français](README.fr.md)

原生 macOS S3/R2 文件管理客户端，主打 Cloudflare R2 日常文件管理，也支持 S3 兼容对象存储。

![Bucket Browser](screens/01-bucket-browser.png)

## 下载与运行

### 从 GitHub Actions 获取

每次推送都会通过 macOS 构建工作流自动上传可运行产物：

- `R2Desk-macOS.zip`
- `R2Desk-macOS.dmg`

打开仓库的 **Actions** 页面，选择最新成功的 **Build macOS App**，下载 `R2Desk-macOS` 产物即可。

### 本地构建

```bash
swift test
swift build
bash scripts/package_app.sh
```

打包文件会生成在：

- `dist/R2Desk-macOS.zip`
- `dist/R2Desk-macOS.dmg`

### 无 Apple Developer 证书打开

应用使用 ad-hoc 签名，不需要付费 Apple Developer 证书。如果 macOS 阻止打开，右键 **R2Desk.app**，选择 **打开** 一次即可。

如仍被拦截，可执行：

```bash
xattr -dr com.apple.quarantine /Applications/R2Desk.app
```

## 功能

### 存储与 Bucket

- 支持 Cloudflare R2 与 S3 兼容 endpoint
- 多 Bucket 管理
- 收藏 Bucket 与最近使用 Bucket
- Cloudflare R2 endpoint 模板
- 保存 Bucket 前后均可测试连接
- 本地配置保存到 `Application Support/R2Desk/config.json`
- Secret Access Key 保存到 macOS 钥匙串
- 支持导入/导出配置，导出时不包含钥匙串密钥

### 文件操作

- 按 Bucket 和 prefix 列出对象
- 通过 S3 prefix 实现类似文件夹的浏览
- 新建文件夹
- 在当前路径内搜索/过滤
- 拖拽上传
- 上传进度、取消上传、重试失败上传
- 自动检测上传文件的 Content-Type
- 上传冲突处理：替换或自动重命名
- 删除单个对象或批量删除已选对象
- 下载单个对象或批量下载已选对象
- 使用系统默认应用打开已下载对象
- 通过 S3 copy + delete 重命名/移动对象
- 复制对象 key
- 复制 S3/R2 直链
- 生成并复制一小时有效的预签名下载链接

### 可见性与效率

- 对象详情：key、大小、修改时间、存储类型、ETag、Content-Type、metadata
- Bucket 使用量汇总
- 本地操作历史
- 上传、下载、删除完成后的 macOS 通知
- 刷新、上传、下载、删除、打开、新建文件夹等快捷键
- 英文与中文界面文案
- GitHub CI 构建与打包

## Cloudflare R2 配置

添加 Bucket 时填写：

- Endpoint：`https://<account-id>.r2.cloudflarestorage.com`
- Region：`auto`
- Bucket Name：你的 R2 bucket 名称
- Access Key ID：你的 R2 API token access key
- Secret Access Key：你的 R2 API token secret

建议 R2 Token 权限：

- Object Read
- Object Write

如果需要删除文件，Token 也需要删除权限。

## 界面截图

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

## 快捷键

| 操作 | 快捷键 |
| --- | --- |
| 刷新 | `⌘R` |
| 上传 | `⌘U` |
| 下载 | `⌘D` |
| 新建文件夹 | `⇧⌘N` |
| 打开 | `Return` |
| 删除 | `Delete` |

## 本地数据

R2Desk 的用户数据全部保存在本机：

- 公开 Bucket 配置：`~/Library/Application Support/R2Desk/config.json`
- 访问密钥：macOS 钥匙串
- 临时打开文件：系统临时目录

配置导出不会包含 Secret Access Key。

## 开发

```bash
swift test
swift build
bash scripts/package_app.sh
```

CI 工作流：

- [`.github/workflows/build-macos.yml`](.github/workflows/build-macos.yml)

打包脚本：

- [`scripts/package_app.sh`](scripts/package_app.sh)

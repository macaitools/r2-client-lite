# S3 Client Lite / R2Desk

**言語:** [English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md) | [বাংলা](README.bn.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Français](README.fr.md)

S3 互換オブジェクトストレージ向けのネイティブ macOS クライアントです。特に Cloudflare R2 の日常的なファイル管理を想定しています。

![Bucket Browser](screens/01-bucket-browser.png)

## ダウンロードと実行

### GitHub Actions から取得

各 push で macOS ビルド workflow が実行され、すぐに使える artifacts がアップロードされます。

- `R2Desk-macOS.zip`
- `R2Desk-macOS.dmg`

リポジトリの **Actions** タブを開き、最新の成功した **Build macOS App** を選び、`R2Desk-macOS` artifact をダウンロードしてください。

### ローカルビルド

```bash
swift test
swift build
bash scripts/package_app.sh
```

パッケージ済みファイルはここに生成されます。

- `dist/R2Desk-macOS.zip`
- `dist/R2Desk-macOS.dmg`

### Apple Developer 証明書なしで開く

アプリは ad-hoc 署名されているため、有料の Apple Developer 証明書は不要です。macOS がダウンロードしたアプリをブロックする場合は、**R2Desk.app** を右クリックして一度 **Open** を選択してください。

必要な場合:

```bash
xattr -dr com.apple.quarantine /Applications/R2Desk.app
```

## 機能

### ストレージと bucket

- Cloudflare R2 と S3 互換 endpoint に対応
- 複数 bucket の管理
- お気に入り bucket と最近使った bucket
- Cloudflare R2 endpoint テンプレート
- bucket 保存前後の接続テスト
- ローカル設定は `Application Support/R2Desk/config.json` に保存
- Secret key は macOS Keychain に保存
- Keychain の secret を含めない設定の import/export

### ファイル操作

- bucket と prefix ごとの object 一覧
- S3 prefix によるフォルダ風ブラウズ
- フォルダ作成
- 現在のパス内で検索/フィルタ
- ドラッグアンドドロップ upload
- upload 進捗、キャンセル、失敗した upload の再試行
- upload 時の Content-Type 自動検出
- upload の競合処理: 置換または自動リネーム
- 単一 object の削除、選択 object の一括削除
- 単一 object の download、選択 object の一括 download
- download 済み object をシステム既定アプリで開く
- S3 copy + delete による object の rename/move
- object key のコピー
- 直接 S3/R2 object URL のコピー
- 1 時間有効な presigned download link の生成とコピー

### 表示と効率

- Object details: key、size、modified time、storage class、ETag、Content-Type、metadata
- bucket 使用量サマリー
- ローカル操作履歴
- upload/download/delete 完了時の macOS 通知
- refresh、upload、download、delete、open、new folder のキーボードショートカット
- 英語と中国語の interface text
- GitHub CI build と packaging

## Cloudflare R2 設定

bucket を追加するときは次を入力します。

- Endpoint: `https://<account-id>.r2.cloudflarestorage.com`
- Region: `auto`
- Bucket Name: R2 bucket 名
- Access Key ID: R2 API token の access key
- Secret Access Key: R2 API token の secret

推奨 R2 token 権限:

- Object Read
- Object Write

削除機能には delete 権限も必要です。

## スクリーンショット

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

## キーボードショートカット

| 操作 | ショートカット |
| --- | --- |
| 更新 | `⌘R` |
| アップロード | `⌘U` |
| ダウンロード | `⌘D` |
| 新規フォルダ | `⇧⌘N` |
| 開く | `Return` |
| 削除 | `Delete` |

## ローカルデータ

R2Desk はすべてのユーザーデータをローカル Mac に保持します。

- 公開 bucket 設定: `~/Library/Application Support/R2Desk/config.json`
- アクセス secret: macOS Keychain
- 一時的に開いたファイル: システム一時ディレクトリ

設定 export には secret key は含まれません。

## 開発

```bash
swift test
swift build
bash scripts/package_app.sh
```

CI workflow:

- [`.github/workflows/build-macos.yml`](.github/workflows/build-macos.yml)

Packaging script:

- [`scripts/package_app.sh`](scripts/package_app.sh)

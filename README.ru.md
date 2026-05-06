# S3 Client Lite / R2Desk

**Языки:** [English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md) | [বাংলা](README.bn.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Français](README.fr.md)

Нативный клиент для macOS для S3-совместимого объектного хранилища, особенно удобный для повседневного управления файлами в Cloudflare R2.

![Bucket Browser](screens/01-bucket-browser.png)

## Скачать и запустить

### Из GitHub Actions

Каждый push запускает workflow сборки macOS и загружает готовые артефакты:

- `R2Desk-macOS.zip`
- `R2Desk-macOS.dmg`

Откройте вкладку **Actions** в репозитории, выберите последний успешный запуск **Build macOS App** и скачайте артефакт `R2Desk-macOS`.

### Локальная сборка

```bash
swift test
swift build
bash scripts/package_app.sh
```

Упакованные файлы появляются здесь:

- `dist/R2Desk-macOS.zip`
- `dist/R2Desk-macOS.dmg`

### Открытие без сертификата Apple Developer

Приложение подписано ad-hoc, поэтому платный сертификат Apple Developer не требуется. Если macOS блокирует скачанное приложение, щелкните правой кнопкой по **R2Desk.app** и один раз выберите **Open**.

При необходимости:

```bash
xattr -dr com.apple.quarantine /Applications/R2Desk.app
```

## Возможности

### Хранилища и buckets

- Поддержка Cloudflare R2 и S3-совместимых endpoints
- Управление несколькими buckets
- Избранные и недавние buckets
- Шаблон endpoint для Cloudflare R2
- Проверка соединения до или после сохранения bucket
- Локальная конфигурация в `Application Support/R2Desk/config.json`
- Секретные ключи хранятся в macOS Keychain
- Импорт/экспорт конфигурации без экспорта секретов Keychain

### Операции с файлами

- Просмотр объектов по bucket и prefix
- Навигация как по папкам через S3 prefixes
- Создание папок
- Поиск/фильтр в текущем пути
- Загрузка перетаскиванием
- Прогресс загрузки, отмена и повтор неудачных загрузок
- Автоматическое определение Content-Type при загрузке
- Обработка конфликтов загрузки: заменить или автоматически переименовать
- Удаление одного объекта или пакетное удаление выбранных объектов
- Скачивание одного объекта или пакетное скачивание выбранных объектов
- Открытие скачанного объекта приложением по умолчанию
- Переименование/перемещение объекта через S3 copy + delete
- Копирование object key
- Копирование прямой S3/R2 object URL
- Создание и копирование presigned-ссылки на скачивание сроком на один час

### Обзор и продуктивность

- Детали объекта: key, размер, время изменения, storage class, ETag, Content-Type, metadata
- Сводка использования bucket
- Локальная история операций
- Уведомления macOS о завершении загрузки, скачивания и удаления
- Горячие клавиши для обновления, загрузки, скачивания, удаления, открытия и новой папки
- Текст интерфейса на английском и китайском
- Сборка и упаковка через GitHub CI

## Настройка Cloudflare R2

При добавлении bucket используйте:

- Endpoint: `https://<account-id>.r2.cloudflarestorage.com`
- Region: `auto`
- Bucket Name: имя вашего R2 bucket
- Access Key ID: access key вашего R2 API token
- Secret Access Key: secret вашего R2 API token

Рекомендуемые права R2 token:

- Object Read
- Object Write

Для удаления файлов также требуется право delete.

## Скриншоты

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

## Горячие клавиши

| Действие | Клавиши |
| --- | --- |
| Обновить | `⌘R` |
| Загрузить | `⌘U` |
| Скачать | `⌘D` |
| Новая папка | `⇧⌘N` |
| Открыть | `Return` |
| Удалить | `Delete` |

## Локальные данные

R2Desk хранит все пользовательские данные на локальном Mac:

- Публичная конфигурация buckets: `~/Library/Application Support/R2Desk/config.json`
- Секреты доступа: macOS Keychain
- Временные открытые файлы: системная временная директория

Экспорт конфигурации не включает секретные ключи.

## Разработка

```bash
swift test
swift build
bash scripts/package_app.sh
```

CI workflow:

- [`.github/workflows/build-macos.yml`](.github/workflows/build-macos.yml)

Скрипт упаковки:

- [`scripts/package_app.sh`](scripts/package_app.sh)

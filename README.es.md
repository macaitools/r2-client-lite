# S3 Client Lite / R2Desk

**Idiomas:** [English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md) | [বাংলা](README.bn.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Français](README.fr.md)

Cliente nativo para macOS para almacenamiento de objetos compatible con S3, pensado especialmente para la gestión diaria de archivos en Cloudflare R2.

![Bucket Browser](screens/01-bucket-browser.png)

## Descargar y ejecutar

### Desde GitHub Actions

Cada push ejecuta el flujo de compilación de macOS y sube artefactos listos para usar:

- `R2Desk-macOS.zip`
- `R2Desk-macOS.dmg`

Abre la pestaña **Actions** del repositorio, elige la última ejecución correcta de **Build macOS App** y descarga el artefacto `R2Desk-macOS`.

### Compilar localmente

```bash
swift test
swift build
bash scripts/package_app.sh
```

Los archivos empaquetados se generan aquí:

- `dist/R2Desk-macOS.zip`
- `dist/R2Desk-macOS.dmg`

### Abrir sin certificado de Apple Developer

La app está firmada ad-hoc, por lo que no requiere un certificado pagado de Apple Developer. Si macOS bloquea la app descargada, haz clic derecho en **R2Desk.app** y elige **Open** una vez.

Si hace falta:

```bash
xattr -dr com.apple.quarantine /Applications/R2Desk.app
```

## Funciones

### Almacenamiento y buckets

- Soporte para Cloudflare R2 y endpoints compatibles con S3
- Gestión de varios buckets
- Buckets favoritos y recientes
- Plantilla de endpoint para Cloudflare R2
- Prueba de conexión antes o después de guardar un bucket
- Configuración local en `Application Support/R2Desk/config.json`
- Claves secretas guardadas en macOS Keychain
- Importación/exportación de configuración sin exportar secretos del Keychain

### Operaciones de archivos

- Listar objetos por bucket y prefix
- Navegación tipo carpeta mediante prefixes de S3
- Crear carpetas
- Buscar/filtrar dentro de la ruta actual
- Subida mediante arrastrar y soltar
- Progreso de subida, cancelación y reintento de subidas fallidas
- Detección automática de Content-Type
- Manejo de conflictos de subida: reemplazar o renombrar automáticamente
- Eliminar un objeto o eliminar objetos seleccionados en lote
- Descargar un objeto o descargar objetos seleccionados en lote
- Abrir objetos descargados con la app predeterminada del sistema
- Renombrar/mover objetos con copy + delete de S3
- Copiar la key del objeto
- Copiar URL directa de S3/R2
- Generar y copiar un enlace de descarga prefirmado válido por una hora

### Visibilidad y productividad

- Detalles del objeto: key, tamaño, fecha de modificación, storage class, ETag, Content-Type, metadata
- Resumen de uso del bucket
- Historial local de operaciones
- Notificaciones de macOS al completar subidas, descargas o eliminaciones
- Atajos de teclado para actualizar, subir, descargar, eliminar, abrir y crear carpeta
- Texto de interfaz en inglés y chino
- Compilación y empaquetado con GitHub CI

## Configuración de Cloudflare R2

Al agregar un bucket, usa:

- Endpoint: `https://<account-id>.r2.cloudflarestorage.com`
- Region: `auto`
- Bucket Name: nombre de tu bucket R2
- Access Key ID: access key de tu token API de R2
- Secret Access Key: secret de tu token API de R2

Permisos recomendados para el token R2:

- Object Read
- Object Write

Para eliminar archivos también se requiere permiso de eliminación.

## Capturas

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

## Atajos de teclado

| Acción | Atajo |
| --- | --- |
| Actualizar | `⌘R` |
| Subir | `⌘U` |
| Descargar | `⌘D` |
| Nueva carpeta | `⇧⌘N` |
| Abrir | `Return` |
| Eliminar | `Delete` |

## Datos locales

R2Desk guarda todos los datos de usuario en el Mac local:

- Configuración pública de buckets: `~/Library/Application Support/R2Desk/config.json`
- Secretos de acceso: macOS Keychain
- Archivos temporales abiertos: directorio temporal del sistema

La exportación de configuración no incluye claves secretas.

## Desarrollo

```bash
swift test
swift build
bash scripts/package_app.sh
```

Flujo CI:

- [`.github/workflows/build-macos.yml`](.github/workflows/build-macos.yml)

Script de empaquetado:

- [`scripts/package_app.sh`](scripts/package_app.sh)

# S3 Client Lite / R2Desk

**Idiomas:** [English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md) | [বাংলা](README.bn.md) | [Português](README.pt.md) | [Русский](README.ru.md) | [日本語](README.ja.md) | [Français](README.fr.md)

Cliente nativo para macOS para armazenamento de objetos compatível com S3, pensado especialmente para o gerenciamento diário de arquivos no Cloudflare R2.

![Bucket Browser](screens/01-bucket-browser.png)

## Baixar e executar

### Pelo GitHub Actions

Cada push executa o workflow de build para macOS e envia artefatos prontos para uso:

- `R2Desk-macOS.zip`
- `R2Desk-macOS.dmg`

Abra a aba **Actions** do repositório, escolha a execução bem-sucedida mais recente de **Build macOS App** e baixe o artefato `R2Desk-macOS`.

### Build local

```bash
swift test
swift build
bash scripts/package_app.sh
```

Os arquivos empacotados são gerados aqui:

- `dist/R2Desk-macOS.zip`
- `dist/R2Desk-macOS.dmg`

### Abrir sem certificado Apple Developer

O app usa assinatura ad-hoc, então não precisa de certificado pago do Apple Developer. Se o macOS bloquear o app baixado, clique com o botão direito em **R2Desk.app** e escolha **Open** uma vez.

Se necessário:

```bash
xattr -dr com.apple.quarantine /Applications/R2Desk.app
```

## Recursos

### Armazenamento e buckets

- Suporte a Cloudflare R2 e endpoints compatíveis com S3
- Gerenciamento de vários buckets
- Buckets favoritos e recentes
- Modelo de endpoint para Cloudflare R2
- Teste de conexão antes ou depois de salvar um bucket
- Configuração local em `Application Support/R2Desk/config.json`
- Chaves secretas salvas no macOS Keychain
- Importação/exportação de configuração sem exportar segredos do Keychain

### Operações de arquivos

- Listar objetos por bucket e prefix
- Navegação estilo pasta usando prefixes do S3
- Criar pastas
- Buscar/filtrar no caminho atual
- Upload por arrastar e soltar
- Progresso de upload, cancelamento e nova tentativa de uploads com falha
- Detecção automática de Content-Type no upload
- Tratamento de conflito no upload: substituir ou renomear automaticamente
- Excluir um objeto ou excluir objetos selecionados em lote
- Baixar um objeto ou baixar objetos selecionados em lote
- Abrir objeto baixado com o app padrão do sistema
- Renomear/mover objeto usando S3 copy + delete
- Copiar object key
- Copiar URL direta de S3/R2
- Gerar e copiar link de download presigned válido por uma hora

### Visibilidade e produtividade

- Detalhes do objeto: key, tamanho, data de modificação, storage class, ETag, Content-Type, metadata
- Resumo de uso do bucket
- Histórico local de operações
- Notificações do macOS para upload/download/exclusão concluídos
- Atalhos de teclado para atualizar, enviar, baixar, excluir, abrir e criar pasta
- Texto de interface em inglês e chinês
- Build e empacotamento com GitHub CI

## Configuração do Cloudflare R2

Ao adicionar um bucket, use:

- Endpoint: `https://<account-id>.r2.cloudflarestorage.com`
- Region: `auto`
- Bucket Name: nome do seu bucket R2
- Access Key ID: access key do seu token API R2
- Secret Access Key: secret do seu token API R2

Permissões recomendadas para o token R2:

- Object Read
- Object Write

Para excluir arquivos, também é necessária permissão de delete.

## Capturas de tela

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

## Atalhos de teclado

| Ação | Atalho |
| --- | --- |
| Atualizar | `⌘R` |
| Enviar | `⌘U` |
| Baixar | `⌘D` |
| Nova pasta | `⇧⌘N` |
| Abrir | `Return` |
| Excluir | `Delete` |

## Dados locais

O R2Desk mantém todos os dados do usuário no Mac local:

- Configuração pública de buckets: `~/Library/Application Support/R2Desk/config.json`
- Segredos de acesso: macOS Keychain
- Arquivos temporários abertos: diretório temporário do sistema

A exportação de configuração não inclui chaves secretas.

## Desenvolvimento

```bash
swift test
swift build
bash scripts/package_app.sh
```

Workflow de CI:

- [`.github/workflows/build-macos.yml`](.github/workflows/build-macos.yml)

Script de empacotamento:

- [`scripts/package_app.sh`](scripts/package_app.sh)

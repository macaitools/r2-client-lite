# R2Desk Design

## Goal

Build a native macOS client for S3-compatible storage, optimized for Cloudflare R2 daily file management.

## Approach

Use a standard SwiftUI macOS app with a sidebar, toolbar, bucket list, and object table. Store connection and bucket metadata locally in Application Support, and store access secrets in the local Keychain. Use direct S3 REST API calls with AWS Signature Version 4 so the app works with Cloudflare R2 and ordinary S3-compatible endpoints without a backend service.

## Options Considered

1. Standard SwiftUI desktop app. This is the chosen approach because it fits macOS file-management behavior, supports a clear multi-bucket UI, and can be built by GitHub Actions without a developer certificate.
2. Menu bar utility plus popover. This is faster for upload-only workflows, but weaker for browsing, deleting, and opening remote objects.
3. Finder-like professional client. This gives the most powerful long-term UX, but adds too much first-version scope.

## Product Shape

- Sidebar shows saved buckets grouped by connection name.
- Main table shows object key, size, modified date, and storage class when available.
- Toolbar supports refresh, upload, open, delete, and settings.
- Bucket settings sheet supports S3/R2 endpoint, region, bucket name, access key, and secret.
- Object opening downloads the file to a temporary local folder and opens it with the system default app.

## Local Data

- `Application Support/R2Desk/config.json` stores profiles and buckets.
- macOS Keychain stores each bucket secret by stable bucket id.
- Temporary downloaded files go under the system temporary directory.

## Error Handling

- Show inline empty, loading, and error states in the main content area.
- Keep destructive delete behind a confirmation dialog.
- Keep network errors human-readable and preserve the original response body when useful.

## Design Direction

Use standard SwiftUI controls so macOS 26/Tahoe can apply the current Liquid Glass appearance automatically. Keep content clear and utilitarian: a translucent sidebar, compact table, restrained accent color, and familiar toolbar icons.

## Testing

Add focused tests for URL construction, S3 signing helpers, byte formatting, and local config round-tripping. Avoid broad snapshot tests or test files for every view in the first version.

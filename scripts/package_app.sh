#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/R2Desk.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$DIST_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_DIR/R2Desk" "$MACOS_DIR/R2Desk"
cp "$ROOT_DIR/Sources/R2Desk/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Sources/R2Desk/Resources/R2Desk.icns" "$RESOURCES_DIR/R2Desk.icns"
printf "APPL????" > "$CONTENTS_DIR/PkgInfo"

chmod +x "$MACOS_DIR/R2Desk"
codesign --force --deep --sign - "$APP_DIR"

(
    cd "$DIST_DIR"
    ditto -c -k --keepParent "R2Desk.app" "R2Desk-macOS.zip"
)

hdiutil create \
    -volname "R2Desk" \
    -srcfolder "$APP_DIR" \
    -ov \
    -format UDZO \
    "$DIST_DIR/R2Desk-macOS.dmg"

echo "Packaged:"
echo "$DIST_DIR/R2Desk-macOS.zip"
echo "$DIST_DIR/R2Desk-macOS.dmg"

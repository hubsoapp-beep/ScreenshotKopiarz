#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/Sources/main.swift"
APP_DIR="$ROOT/build/ScreenshotKopiarz.app"
BIN_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"

echo ">>> Kompilacja..."
mkdir -p "$BIN_DIR" "$RES_DIR"
swiftc -O \
  -o "$BIN_DIR/ScreenshotKopiarz" \
  -framework AppKit \
  -framework CoreServices \
  -framework UserNotifications \
  "$SRC"

echo ">>> Kopiowanie Info.plist..."
cp "$ROOT/Info.plist" "$APP_DIR/Contents/Info.plist"

echo ">>> Gotowe: $APP_DIR"

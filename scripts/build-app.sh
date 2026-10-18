#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
case "$CONFIGURATION" in
    debug|release) ;;
    *) echo "Usage: bash scripts/build-app.sh [debug|release]" >&2; exit 2 ;;
esac

cd "$PROJECT_DIR"
swift build --configuration "$CONFIGURATION"
BIN_DIR="$(swift build --configuration "$CONFIGURATION" --show-bin-path)"
APP_DIR="$PROJECT_DIR/dist/LidDisconnect.app"
mkdir -p "$APP_DIR/Contents/MacOS"
/usr/bin/install -m 755 "$BIN_DIR/LidDisconnect" "$APP_DIR/Contents/MacOS/LidDisconnect"
/bin/cp "$PROJECT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
/usr/bin/plutil -lint "$APP_DIR/Contents/Info.plist"
# Local ad-hoc signature. No developer certificate, network service or sudo required.
/usr/bin/codesign --force --sign - --identifier com.soda916.LidDisconnect "$APP_DIR"
/usr/bin/codesign --verify --strict "$APP_DIR"
echo "Built: $APP_DIR"
echo "Run: open \"$APP_DIR\""

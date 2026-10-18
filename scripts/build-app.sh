#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-debug}"
ARCHITECTURE="${2:-native}"
case "$CONFIGURATION" in
    debug|release) ;;
    *) echo "Usage: bash scripts/build-app.sh [debug|release] [native|universal|arm64|x86_64]" >&2; exit 2 ;;
esac

cd "$PROJECT_DIR"
SWIFT_ARGS=(--configuration "$CONFIGURATION")
case "$ARCHITECTURE" in
    native) ;;
    universal) SWIFT_ARGS+=(--arch arm64 --arch x86_64 --build-path "$PROJECT_DIR/.build/universal") ;;
    arm64|x86_64) SWIFT_ARGS+=(--arch "$ARCHITECTURE" --build-path "$PROJECT_DIR/.build/$ARCHITECTURE") ;;
    *) echo "Unsupported architecture: $ARCHITECTURE" >&2; exit 2 ;;
esac
swift build "${SWIFT_ARGS[@]}"
BIN_DIR="$(swift build "${SWIFT_ARGS[@]}" --show-bin-path)"
APP_DIR="$PROJECT_DIR/build/LidDisconnect.app"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/MacOS" "$RESOURCES_DIR"
/usr/bin/install -m 755 "$BIN_DIR/LidDisconnect" "$APP_DIR/Contents/MacOS/LidDisconnect"
/bin/cp "$PROJECT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
/usr/bin/ditto "$BIN_DIR/LidDisconnect_LidDisconnectCore.bundle" "$RESOURCES_DIR/LidDisconnect_LidDisconnectCore.bundle"
for locale_dir in "$PROJECT_DIR"/Sources/LidDisconnectCore/Resources/*.lproj; do
    locale_name="$(basename "$locale_dir")"
    mkdir -p "$RESOURCES_DIR/$locale_name"
    /bin/cp "$locale_dir/InfoPlist.strings" "$RESOURCES_DIR/$locale_name/InfoPlist.strings"
done
/bin/cp "$PROJECT_DIR/LICENSE" "$PROJECT_DIR/NOTICE" "$RESOURCES_DIR/"
/usr/bin/plutil -lint "$APP_DIR/Contents/Info.plist"
# Local ad-hoc signature. No developer certificate, network service or sudo required.
/usr/bin/codesign --force --sign - --identifier com.soda916.LidDisconnect "$APP_DIR"
/usr/bin/codesign --verify --deep --strict "$APP_DIR"
if [ "$ARCHITECTURE" = universal ]; then
    /usr/bin/lipo "$APP_DIR/Contents/MacOS/LidDisconnect" -verify_arch arm64
    /usr/bin/lipo "$APP_DIR/Contents/MacOS/LidDisconnect" -verify_arch x86_64
fi
"$APP_DIR/Contents/MacOS/LidDisconnect" --check-localizations
echo "Built: $APP_DIR"
echo "Run: open \"$APP_DIR\""

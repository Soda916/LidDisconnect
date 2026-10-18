#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Packaging/Info.plist)"
case "$VERSION" in
    *[!0-9.]*|'') echo "Invalid release version" >&2; exit 2 ;;
esac
bash scripts/build-app.sh release universal
NAME="LidDisconnect-v$VERSION-macOS-Universal"
STAGING_DIR="$(mktemp -d "$PROJECT_DIR/build/dmg-stage.XXXXXX")"
trap 'case "$STAGING_DIR" in "$PROJECT_DIR"/build/dmg-stage.*) /bin/rm -rf "$STAGING_DIR" ;; esac' EXIT
/usr/bin/ditto build/LidDisconnect.app "$STAGING_DIR/LidDisconnect.app"
/bin/ln -s /Applications "$STAGING_DIR/Applications"
/bin/cp LICENSE NOTICE Packaging/INSTALL.txt "$STAGING_DIR/"
/usr/bin/hdiutil create -volname "LidDisconnect $VERSION" -srcfolder "$STAGING_DIR" -ov -format UDZO -fs HFS+ "build/$NAME.dmg"
/usr/bin/hdiutil verify "build/$NAME.dmg"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent build/LidDisconnect.app "build/$NAME.zip"
cd build
/usr/bin/shasum -a 256 "$NAME.dmg" "$NAME.zip" > SHA256SUMS.txt
/usr/bin/shasum -a 256 -c SHA256SUMS.txt
echo "Release artifacts: $PROJECT_DIR/build/"

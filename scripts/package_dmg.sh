#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-build/DerivedData}"
DIST_DIR="${DIST_DIR:-build/dist}"
STAGING_DIR="$DIST_DIR/dmg-root"
APP_NAME="Clipy.app"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME"
STAGED_APP_PATH="$STAGING_DIR/$APP_NAME"
DMG_PATH="$DIST_DIR/Clipy-$CONFIGURATION-arm64.dmg"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

rm -rf "$DIST_DIR"
mkdir -p "$STAGING_DIR"

xcodebuild \
  -project Clipy.xcodeproj \
  -scheme Clipy \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -skipPackagePluginValidation \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app was not produced at $APP_PATH" >&2
  exit 1
fi

cp -R "$APP_PATH" "$STAGED_APP_PATH"

if [[ "$CODE_SIGN_IDENTITY" == "-" ]]; then
  codesign --force --deep --sign - "$STAGED_APP_PATH"
else
  codesign --force --deep --sign "$CODE_SIGN_IDENTITY" --options runtime --timestamp "$STAGED_APP_PATH"
fi
codesign --verify --deep --strict --verbose=2 "$STAGED_APP_PATH"

lipo -info "$STAGED_APP_PATH/Contents/MacOS/Clipy"

ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "Clipy" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if [[ "$CODE_SIGN_IDENTITY" != "-" ]]; then
  codesign --force --sign "$CODE_SIGN_IDENTITY" --timestamp "$DMG_PATH"
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
  xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
fi

echo "Created $DMG_PATH"

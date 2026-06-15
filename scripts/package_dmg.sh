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
  -skipMacroValidation \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  ENABLE_TESTABILITY=YES \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app was not produced at $APP_PATH" >&2
  exit 1
fi

cp -R "$APP_PATH" "$STAGED_APP_PATH"

rm -rf "$STAGED_APP_PATH/Contents/PlugIns"
for fw in XCTest XCTestCore XCTestSupport XCTAutomationSupport XCUIAutomation XCUnit Testing; do
  rm -rf "$STAGED_APP_PATH/Contents/Frameworks/${fw}.framework"
done
rm -f "$STAGED_APP_PATH/Contents/Frameworks/libXCTestBundleInject.dylib"
rm -f "$STAGED_APP_PATH/Contents/Frameworks/libXCTestSwiftSupport.dylib"

# Embed SPM dynamic frameworks that are linked via @rpath but not auto-embedded
# by Xcode (e.g. IssueReporting / IssueReportingPackageSupport from pointfree
# deps). Without these the app crashes at launch with a dyld
# "Library not loaded: @rpath/...framework" error. Resolve transitively.
PACKAGE_FRAMEWORKS="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/PackageFrameworks"
FRAMEWORKS_DIR="$STAGED_APP_PATH/Contents/Frameworks"

embed_rpath_frameworks() {
  local binary="$1" ref fw dest
  while read -r ref; do
    fw=$(printf '%s\n' "$ref" | sed -E 's#@rpath/([^/]+\.framework)/.*#\1#')
    [[ "$fw" == *.framework ]] || continue
    dest="$FRAMEWORKS_DIR/$fw"
    if [[ ! -e "$dest" && -e "$PACKAGE_FRAMEWORKS/$fw" ]]; then
      echo "Embedding $fw"
      cp -R "$PACKAGE_FRAMEWORKS/$fw" "$dest"
      embed_rpath_frameworks "$dest/${fw%.framework}"
    fi
  done < <(otool -L "$binary" 2>/dev/null | awk '/@rpath\/.*\.framework\//{print $1}')
}

embed_rpath_frameworks "$STAGED_APP_PATH/Contents/MacOS/Clipy"

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

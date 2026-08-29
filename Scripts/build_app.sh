#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ItoCanvas"
BUNDLE_ID="com.oscarzhu.itocanvas"
VERSION="1.0.1"
BUILD="1"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
CONTENTS="$APP/Contents"

cd "$ROOT"
swift build -c release

/usr/bin/python3 - "$APP" <<'PY'
import shutil, sys
shutil.rmtree(sys.argv[1], ignore_errors=True)
PY
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
install -m 755 "$ROOT/.build/release/$APP_NAME" "$CONTENTS/MacOS/$APP_NAME"

if [[ ! -f "$ROOT/Resources/AppIcon.icns" ]]; then
  "$ROOT/Scripts/generate_icon.sh"
fi
install -m 644 "$ROOT/Resources/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"

PLIST="$CONTENTS/Info.plist"
plutil -create xml1 "$PLIST"
plutil -insert CFBundleDevelopmentRegion -string en "$PLIST"
plutil -insert CFBundleDisplayName -string "$APP_NAME" "$PLIST"
plutil -insert CFBundleExecutable -string "$APP_NAME" "$PLIST"
plutil -insert CFBundleIconFile -string AppIcon "$PLIST"
plutil -insert CFBundleIdentifier -string "$BUNDLE_ID" "$PLIST"
plutil -insert CFBundleInfoDictionaryVersion -string 6.0 "$PLIST"
plutil -insert CFBundleName -string "$APP_NAME" "$PLIST"
plutil -insert CFBundlePackageType -string APPL "$PLIST"
plutil -insert CFBundleShortVersionString -string "$VERSION" "$PLIST"
plutil -insert CFBundleVersion -string "$BUILD" "$PLIST"
plutil -insert LSApplicationCategoryType -string public.app-category.finance "$PLIST"
plutil -insert LSMinimumSystemVersion -string 14.0 "$PLIST"
plutil -insert NSHighResolutionCapable -bool true "$PLIST"
plutil -insert NSHumanReadableCopyright -string "Copyright © 2026 Oscar Zhu. All rights reserved." "$PLIST"

codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

echo "Built $APP"

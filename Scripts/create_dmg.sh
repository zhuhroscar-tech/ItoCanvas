#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ItoCanvas"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
STAGING="$DIST/staging"
DMG="$DIST/$APP_NAME.dmg"

if [[ ! -d "$APP" ]]; then
  "$ROOT/Scripts/build_app.sh"
fi

/usr/bin/python3 - "$STAGING" "$DMG" <<'PY'
import os, shutil, sys
shutil.rmtree(sys.argv[1], ignore_errors=True)
try:
    os.remove(sys.argv[2])
except FileNotFoundError:
    pass
PY
mkdir -p "$STAGING"
ditto "$APP" "$STAGING/$APP_NAME.app"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG"

hdiutil imageinfo "$DMG" >/dev/null
echo "Created $DMG"

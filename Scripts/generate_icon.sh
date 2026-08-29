#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$ROOT/.build/ItoCanvas.iconset"
OUTPUT_DIR="$ROOT/Resources"

mkdir -p "$ICONSET" "$OUTPUT_DIR"
/usr/bin/swift "$ROOT/Scripts/generate_icon.swift" "$ICONSET"
iconutil -c icns "$ICONSET" -o "$OUTPUT_DIR/AppIcon.icns"
echo "Generated $OUTPUT_DIR/AppIcon.icns"

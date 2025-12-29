#!/usr/bin/env bash
set -euo pipefail

# Build the Flutter dashboard web app and copy it into website/public/dashboard
# so it is served at https://love2learnsign.com/dashboard

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DASH_DIR="${ROOT_DIR}/../dashboard"
OUT_DIR="${ROOT_DIR}/public/dashboard"

echo "[dashboard] Building Flutter web (base-href=/dashboard/)"
cd "$DASH_DIR"
flutter clean
flutter build web --base-href /dashboard/

echo "[dashboard] Copying build artifacts to: $OUT_DIR"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cp -R "$DASH_DIR/build/web/"* "$OUT_DIR/"

echo "[dashboard] Done"



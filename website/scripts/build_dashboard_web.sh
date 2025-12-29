#!/usr/bin/env bash
set -euo pipefail

# Build the Flutter dashboard web app and copy it into website/public/dashboard-app
# so it can be embedded by the site at:
# - /sign-in (Next.js login)
# - /dashboard (Next.js wrapper + iframe)

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DASH_DIR="${ROOT_DIR}/../dashboard"
OUT_DIR="${ROOT_DIR}/public/dashboard-app"

echo "[dashboard] Building Flutter web (base-href=/dashboard-app/)"
cd "$DASH_DIR"
flutter clean
flutter build web --base-href /dashboard-app/

echo "[dashboard] Copying build artifacts to: $OUT_DIR"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cp -R "$DASH_DIR/build/web/"* "$OUT_DIR/"

echo "[dashboard] Done"



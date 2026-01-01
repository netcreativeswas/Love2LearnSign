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

# App Check (web) needs the reCAPTCHA v3 SITE KEY at build time.
# Provide it via environment variable (public value, safe to embed in JS):
#   export L2L_RECAPTCHA_SITE_KEY="..."
# Then run this script.
if [ -z "${L2L_RECAPTCHA_SITE_KEY:-}" ]; then
  echo "[dashboard][warn] L2L_RECAPTCHA_SITE_KEY is not set; App Check will NOT be activated in the dashboard build."
flutter build web --base-href /dashboard-app/
else
  flutter build web \
    --base-href /dashboard-app/ \
    --dart-define=L2L_RECAPTCHA_SITE_KEY="${L2L_RECAPTCHA_SITE_KEY}"
fi

echo "[dashboard] Copying build artifacts to: $OUT_DIR"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cp -R "$DASH_DIR/build/web/"* "$OUT_DIR/"

echo "[dashboard] Done"



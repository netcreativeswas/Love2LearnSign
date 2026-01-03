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

# App Check (web) needs the reCAPTCHA v3 SITE KEY at build time (public value).
# Provide it via environment variable:
#   export NEXT_PUBLIC_RECAPTCHA_SITE_KEY="..."   # (preferred, same as the website)
# or:
#   export L2L_RECAPTCHA_SITE_KEY="..."           # (legacy alias)
# Then run this script.
KEY="${L2L_RECAPTCHA_SITE_KEY:-${NEXT_PUBLIC_RECAPTCHA_SITE_KEY:-}}"
if [ -z "${KEY:-}" ]; then
  echo "[dashboard][warn] NEXT_PUBLIC_RECAPTCHA_SITE_KEY (or L2L_RECAPTCHA_SITE_KEY) is not set; App Check will NOT be activated in the dashboard build."
flutter build web --base-href /dashboard-app/
else
  flutter build web \
    --base-href /dashboard-app/ \
    --dart-define=L2L_RECAPTCHA_SITE_KEY="${KEY}"
fi

echo "[dashboard] Copying build artifacts to: $OUT_DIR"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cp -R "$DASH_DIR/build/web/"* "$OUT_DIR/"

echo "[dashboard] Done"



#!/usr/bin/env bash
set -e

# ── 1️⃣ Build the Flutter client (dictionary) ─────────────────────────────
if [ -d "../love_to_learn_sign" ]; then
  cd ../love_to_learn_sign
  flutter clean
  flutter build web
  CLIENT_BUILD_SOURCE="../love_to_learn_sign/build/web"
  cd - >/dev/null
else
  echo "[info] ../love_to_learn_sign not found. Using prebuilt dictionary_web_build as source."
  CLIENT_BUILD_SOURCE="./dictionary_web_build"
fi

# ── 2️⃣ Build the Flutter admin dashboard ────────────────────────────────
# This repo is named `dashboard/` in this workspace.
cd "$(dirname "$0")"
flutter clean
# tell Flutter to inject /admin/ into your base href placeholder
# Use HTML renderer to avoid WebGL context issues
flutter build web --base-href /admin/

# ── 3️⃣ Prepare `public/`, preserving /admin, /word, and /.well-known ────
# back to the hosting dir
cd "$(dirname "$0")"
mkdir -p public

# remove everything except the admin, word, splash, and .well-known folders
shopt -s extglob
# rm -rf public/!(admin)
rm -rf public/!(admin|word|splash|.well-known)

# ── 4️⃣ Copy the client build into `public/` ─────────────────────────────
cp -R ${CLIENT_BUILD_SOURCE}/* public/

# ── 5️⃣ Copy the admin build into `public/admin/` ────────────────────────
rm -rf public/admin
mkdir -p public/admin
cp -R build/web/* public/admin/

# ── 6️⃣ Copy your assetlinks.json for App Links ────────────────────────
mkdir -p public/.well-known
cp ~/Downloads/assetlinks.json public/.well-known/assetlinks.json

# ── 7️⃣ Deploy to Firebase Hosting ───────────────────────────────────────
# Explicit project avoids "No currently active project" errors.
firebase deploy --only hosting --project love-to-learn-sign

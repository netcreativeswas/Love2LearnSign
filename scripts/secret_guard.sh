#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[secret-guard] ERROR: $1" >&2
  exit 1
}

echo "[secret-guard] Running repo secret checks..."

# 1) Block known secret files from being tracked
if git ls-files --error-unmatch "app/android/key.properties" >/dev/null 2>&1; then
  fail "app/android/key.properties is tracked by git. It must be local-only (use key.properties.example)."
fi

if git ls-files | grep -E '\.(jks|keystore|p12|pem|mobileprovision|p8|key|crt|cer|der)$' >/dev/null 2>&1; then
  fail "A private key / certificate file appears to be tracked by git. Remove it and rewrite history if needed."
fi

# 2) Block obvious password patterns anywhere in tracked files
if git grep -nE '^(storePassword|keyPassword)\s*=' -- ':!**/*.example' >/dev/null 2>&1; then
  fail "Found storePassword/keyPassword in tracked files. These must never be committed."
fi

echo "[secret-guard] OK"



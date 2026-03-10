#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Usage:
#   ./scripts/testflight.sh
#   SCHEME=BetterLife BUILD_NUMBER=123 ./scripts/testflight.sh
#
# Auth (recommended): App Store Connect API Key
#   export ASC_KEY_ID="ABC123DEF4"
#   export ASC_ISSUER_ID="11223344-5566-7788-99AA-BBCCDDEEFF00"
#   export ASC_KEY_FILEPATH="$HOME/secrets/AuthKey_ABC123DEF4.p8"
#   # OR
#   export ASC_KEY_BASE64="<base64 of .p8>"
#
# Notes:
# - First upload requires the bundle id to be registered in App Store Connect.

if [[ ! -f Gemfile ]]; then
  echo "Gemfile not found; run from repo root." >&2
  exit 1
fi

if ! command -v bundle >/dev/null 2>&1; then
  echo "Bundler not found. Install Ruby/Bundler first (e.g. 'gem install bundler')." >&2
  exit 1
fi

# Load local env if present
# .env should be shell-compatible, e.g.:
#   ASC_KEY_FILEPATH="/Users/jason/Documents/Mobile App/AuthKey_XXXX.p8"
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

# Avoid sudo by installing gems locally (Bundler 1.x compatible)
mkdir -p vendor/bundle
bundle install --path vendor/bundle
bundle exec fastlane ios beta

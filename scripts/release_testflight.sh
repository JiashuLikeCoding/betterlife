#!/usr/bin/env bash
set -euo pipefail

# One-command flow:
# - stage & commit local changes (if any)
# - push to origin
# - upload to TestFlight via ./scripts/testflight.sh
#
# Usage:
#   ./scripts/release_testflight.sh "fix: improve dark mode contrast"
#
# Notes:
# - Requires git remote 'origin' to be configured.
# - Requires .env (or environment variables) for ASC API key.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# Ensure UTF-8 locale (fastlane can crash with US-ASCII in some environments)
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

MSG="${1:-}"

if [[ -z "$MSG" ]]; then
  echo "Error: commit message required."
  echo "Usage: $0 \"<commit message>\""
  exit 2
fi

# Ensure git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository."
  exit 2
fi

# Stage & commit if there are changes
if [[ -n "$(git status --porcelain)" ]]; then
  git add -A
  if git diff --cached --quiet; then
    echo "No staged changes after git add -A; nothing to commit."
  else
    git commit -m "$MSG"
  fi
else
  echo "Working tree clean; skipping commit."
fi

# Push (if branch has upstream configured, this is a no-op safe push)
CURRENT_BRANCH="$(git branch --show-current)"
if [[ -z "$CURRENT_BRANCH" ]]; then
  echo "Error: could not detect current branch."
  exit 2
fi

git push

echo "---"

echo "Uploading to TestFlight..."
./scripts/testflight.sh

echo "Done."

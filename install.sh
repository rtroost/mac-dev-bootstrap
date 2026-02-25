#!/usr/bin/env bash
set -euo pipefail

# Anonymous installer entrypoint.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/rtroost/mac-dev-bootstrap/main/install.sh | bash
#
# Optional env vars:
#   BRANCH=main REF=<commit-ish> NONINTERACTIVE=1

REPO_OWNER="rtroost"
REPO_NAME="mac-dev-bootstrap"
BRANCH="${BRANCH:-main}"
REF="${REF:-}"
NONINTERACTIVE="${NONINTERACTIVE:-0}"

if [[ "${OSTYPE:-}" != "darwin"* ]]; then
  echo "❌ This installer is for macOS only."
  exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "❌ curl is required."; exit 1; }
command -v tar  >/dev/null 2>&1 || { echo "❌ tar is required.";  exit 1; }

if [[ -n "$REF" ]]; then
  SRC_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/${REF}.tar.gz"
  SRC_DIR="${REPO_NAME}-${REF}"
else
  SRC_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${BRANCH}.tar.gz"
  SRC_DIR="${REPO_NAME}-${BRANCH}"
fi

echo "🚀 mac-dev-bootstrap"
echo "📦 Source: ${REPO_OWNER}/${REPO_NAME} (${REF:-$BRANCH})"
echo "⬇️  URL: ${SRC_URL}"

if [[ "$NONINTERACTIVE" != "1" ]]; then
  echo
  echo "This will download and run bootstrap scripts on your machine."
  read -r -p "Continue? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

curl -fsSL "$SRC_URL" -o "$TMP_DIR/src.tgz"
tar -xzf "$TMP_DIR/src.tgz" -C "$TMP_DIR"

cd "$TMP_DIR/$SRC_DIR"
chmod +x bootstrap.sh vscode-settings-sync.sh macos-defaults.sh security.sh
NONINTERACTIVE="$NONINTERACTIVE" ./bootstrap.sh
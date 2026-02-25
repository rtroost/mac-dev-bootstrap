#!/usr/bin/env bash
set -euo pipefail

VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"

# Enable Settings Sync in VS Code user settings (idempotent).
# The user still needs to sign in once via the GUI to link their account.

if ! command -v jq >/dev/null 2>&1; then
  echo "⚠️  jq not found — skipping VS Code settings sync configuration."
  echo "   Run 'brew install jq' and try again."
  exit 0
fi

mkdir -p "$VSCODE_SETTINGS_DIR"

if [[ ! -f "$VSCODE_SETTINGS_FILE" ]]; then
  echo '{}' > "$VSCODE_SETTINGS_FILE"
fi

tmp="$(mktemp)"
jq '. + {"settingsSync.keybindingsPerPlatform": true}' "$VSCODE_SETTINGS_FILE" > "$tmp"
mv "$tmp" "$VSCODE_SETTINGS_FILE"

echo "✅ VS Code Settings Sync is configured."
echo
echo "To complete setup, open VS Code and sign in to Settings Sync:"
echo "  Cmd+Shift+P → \"Settings Sync: Turn On...\""
echo "  Sign in with GitHub to sync extensions, settings, and keybindings."

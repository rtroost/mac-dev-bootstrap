#!/usr/bin/env bash
set -euo pipefail

# Use log() from parent bootstrap.sh; define fallback if run standalone
if ! declare -f log >/dev/null 2>&1; then
  log() { printf "\n\033[1m%s\033[0m\n" "$*"; }
fi

log "💻 Configuring VS Code Settings Sync..."

VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"

# Enable Settings Sync in VS Code user settings (idempotent).
# The user still needs to sign in once via the GUI to link their account.

mkdir -p "$VSCODE_SETTINGS_DIR"

if [[ ! -f "$VSCODE_SETTINGS_FILE" ]]; then
  echo "  → Creating $VSCODE_SETTINGS_FILE"
  echo '{}' > "$VSCODE_SETTINGS_FILE"
else
  echo "  → Updating $VSCODE_SETTINGS_FILE"
fi

# jq is installed via Brewfile; skip if unavailable to avoid clobbering settings
if command -v jq >/dev/null 2>&1; then
  jq '. + {"settingsSync.keybindingsPerPlatform": true}' "$VSCODE_SETTINGS_FILE" > "$VSCODE_SETTINGS_FILE.tmp"
  mv "$VSCODE_SETTINGS_FILE.tmp" "$VSCODE_SETTINGS_FILE"
else
  echo "⚠️  jq not found — skipping settings merge to avoid overwriting existing configuration."
  echo "   Install jq (brew install jq) and re-run, or add the setting manually."
fi

echo "✅ VS Code Settings Sync is configured."
echo
echo "To complete setup, open VS Code and sign in to Settings Sync:"
echo "  Cmd+Shift+P → \"Settings Sync: Turn On...\""
echo "  Sign in with GitHub to sync extensions, settings, and keybindings."

#!/usr/bin/env bash
set -euo pipefail

VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"
SETTING_KEY='"settingsSync.keybindingsPerPlatform"'
SETTING_LINE='  "settingsSync.keybindingsPerPlatform": true'

# Enable Settings Sync in VS Code user settings (idempotent).
# The user still needs to sign in once via the GUI to link their account.

mkdir -p "$VSCODE_SETTINGS_DIR"

if [[ ! -f "$VSCODE_SETTINGS_FILE" ]]; then
  echo '{}' > "$VSCODE_SETTINGS_FILE"
fi

tmp="$(mktemp)"
if command -v jq >/dev/null 2>&1 && jq -e . "$VSCODE_SETTINGS_FILE" >/dev/null 2>&1; then
  jq '. + {"settingsSync.keybindingsPerPlatform": true}' "$VSCODE_SETTINGS_FILE" > "$tmp"
elif grep -Eq "^[[:space:]]*${SETTING_KEY}[[:space:]]*:" "$VSCODE_SETTINGS_FILE"; then
  sed -E "s|^[[:space:]]*${SETTING_KEY}[[:space:]]*:[[:space:]]*[^,]*,?|${SETTING_LINE},|" \
    "$VSCODE_SETTINGS_FILE" > "$tmp"
elif grep -q '}' "$VSCODE_SETTINGS_FILE"; then
  awk -v setting_line="$SETTING_LINE" '
    {
      lines[++count] = $0
    }
    END {
      for (i = count; i >= 1; i--) {
        if (match(lines[i], /\}/)) {
          close_idx = i
          close_pos = RSTART
          break
        }
      }

      if (!close_idx) {
        print "{"
        print setting_line
        print "}"
        exit
      }

      close_line = lines[close_idx]
      before_close = substr(close_line, 1, close_pos - 1)
      after_close = substr(close_line, close_pos)

      trimmed_before = before_close
      sub(/[[:space:]]+$/, "", trimmed_before)
      sub(/^[[:space:]]+/, "", trimmed_before)

      if (trimmed_before != "" && trimmed_before != "{") {
        has_inline_content = 1
      }

      if (has_inline_content) {
        before_no_ws = before_close
        sub(/[[:space:]]+$/, "", before_no_ws)
        if (before_no_ws !~ /,[[:space:]]*$/) {
          before_close = before_no_ws ","
        } else {
          before_close = before_no_ws
        }
      } else {
        for (i = close_idx - 1; i >= 1; i--) {
          if (lines[i] ~ /^[[:space:]]*$/) {
            continue
          }
          if (lines[i] ~ /^[[:space:]]*\/\//) {
            continue
          }
          if (lines[i] ~ /^[[:space:]]*\{[[:space:]]*$/) {
            continue
          }
          prev_idx = i
          break
        }

        if (prev_idx && lines[prev_idx] !~ /,[[:space:]]*$/) {
          lines[prev_idx] = lines[prev_idx] ","
        }
      }

      for (i = 1; i < close_idx; i++) {
        print lines[i]
      }

      if (before_close ~ /[^[:space:]]/) {
        print before_close
      }
      print setting_line
      print after_close
      for (i = close_idx + 1; i <= count; i++) {
        print lines[i]
      }
    }
  ' "$VSCODE_SETTINGS_FILE" > "$tmp"
else
  cat > "$tmp" <<EOF
{
$SETTING_LINE
}
EOF
fi

mv "$tmp" "$VSCODE_SETTINGS_FILE"

echo "✅ VS Code Settings Sync is configured."
echo
echo "To complete setup, open VS Code and sign in to Settings Sync:"
echo "  Cmd+Shift+P → \"Settings Sync: Turn On...\""
echo "  Sign in with GitHub to sync extensions, settings, and keybindings."

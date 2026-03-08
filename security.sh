#!/usr/bin/env bash
set -euo pipefail

# Use log() from parent bootstrap.sh; define fallback if run standalone
if ! declare -f log >/dev/null 2>&1; then
  log() { printf "\n\033[1m%s\033[0m\n" "$*"; }
fi

MACOS_MAJOR="$(sw_vers -productVersion | cut -d. -f1)"

# Enable application firewall
log "🔥 Enabling application firewall..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Enable stealth mode (don't respond to ICMP ping or TCP/UDP probes on closed ports)
log "👻 Enabling stealth mode..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Disable guest account
log "🚫 Disabling guest account..."
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

# Require password immediately after sleep or screen saver.
# On macOS 13+ (Ventura), these defaults are ignored — the setting is managed
# via System Settings > Lock Screen. We still set them for older systems.
log "🔒 Requiring password immediately after sleep/screensaver..."
if [[ "$MACOS_MAJOR" -ge 13 ]]; then
  echo "  → macOS $MACOS_MAJOR detected — configure via System Settings > Lock Screen > \"Require password after screen saver begins or display is turned off\" → Immediately"
else
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0
fi

# Check FileVault status
log "💽 Checking FileVault status..."
if fdesetup status | grep -q "FileVault is Off"; then
  echo "⚠️  FileVault is disabled. Enable it via System Settings > Privacy & Security > FileVault"
  echo "   Or run: sudo fdesetup enable"
fi

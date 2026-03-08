#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n\033[1m%s\033[0m\n" "$*"; }

# Enable application firewall
log "🔥 Enabling application firewall..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Enable stealth mode (don't respond to ICMP ping or TCP/UDP probes on closed ports)
log "👻 Enabling stealth mode..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Disable guest account
log "🚫 Disabling guest account..."
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

# Require password immediately after sleep or screen saver
log "🔒 Requiring password immediately after sleep/screensaver..."
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Check FileVault status
log "💽 Checking FileVault status..."
if fdesetup status | grep -q "FileVault is Off"; then
  echo "⚠️  FileVault is disabled. Enable it via System Settings → Privacy & Security → FileVault"
  echo "   Or run: sudo fdesetup enable"
fi

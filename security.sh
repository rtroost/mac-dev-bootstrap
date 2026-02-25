#!/usr/bin/env bash
set -euo pipefail

# Enable application firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Enable stealth mode (don't respond to ICMP ping or TCP/UDP probes on closed ports)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Disable guest account
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

# Require password immediately after sleep or screen saver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Check FileVault status
if fdesetup status | grep -q "FileVault is Off"; then
  echo "⚠️  FileVault is disabled. Enable it via System Settings → Privacy & Security → FileVault"
  echo "   Or run: sudo fdesetup enable"
fi

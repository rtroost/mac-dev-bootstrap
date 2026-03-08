#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n\033[1m%s\033[0m\n" "$*"; }

# Keyboard
log "⌨️  Setting keyboard repeat rate..."
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Finder
log "📂 Configuring Finder (show hidden files, path bar, status bar)..."
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Avoid .DS_Store on network and USB drives
log "🚫 Disabling .DS_Store on network and USB drives..."
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Dock
log "🔲 Configuring Dock (autohide, no delay)..."
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3

# Screenshots: save to ~/Screenshots, PNG format, no shadow
log "📸 Configuring screenshots (~/Screenshots, PNG, no shadow)..."
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# Disable the "Are you sure you want to open this application?" dialog
log "🚫 Disabling Gatekeeper application quarantine dialog..."
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Restart affected apps
log "🔄 Restarting Finder, Dock, and SystemUIServer..."
killall Finder || true
killall Dock || true
killall SystemUIServer || true

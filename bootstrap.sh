#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NONINTERACTIVE="${NONINTERACTIVE:-0}"

log() { printf "\n\033[1m%s\033[0m\n" "$*"; }

ask() {
  local prompt="$1" default="${2:-}"
  if [[ "$NONINTERACTIVE" == "1" ]]; then
    echo "$default"
    return 0
  fi
  if [[ -n "$default" ]]; then
    read -r -p "$prompt [$default]: " reply
    echo "${reply:-$default}"
  else
    read -r -p "$prompt: " reply
    echo "$reply"
  fi
}

ask_yn() {
  local prompt="$1" default="${2:-N}"
  if [[ "$NONINTERACTIVE" == "1" ]]; then
    [[ "$default" =~ ^[Yy]$ ]] && return 0 || return 1
  fi
  read -r -p "$prompt [y/N]: " reply
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

if [[ "${OSTYPE:-}" != "darwin"* ]]; then
  echo "❌ This script is for macOS only." >&2
  exit 1
fi

log "🚀 Starting macOS Dev Bootstrap"

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  log "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Apple Silicon vs Intel
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  eval "$(brew shellenv)"
fi

log "📦 Installing packages from Brewfile..."
brew update
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="$SCRIPT_DIR/Brewfile"

# zsh integrations (idempotent managed block — replaced on every run)
log "🐚 Configuring zsh integrations..."
ZSHRC="$HOME/.zshrc"
MARKER_BEGIN="# >>> mac-dev-bootstrap >>>"
MARKER_END="# <<< mac-dev-bootstrap <<<"

# Quoted heredoc (<<'BLOCK') prevents expansion — these expressions are written
# literally to .zshrc and expanded when zsh sources the file.
MANAGED_BLOCK=$(cat <<'BLOCK'
# >>> mac-dev-bootstrap >>>
# Managed block — automatically replaced by bootstrap.sh.
if command -v mise >/dev/null 2>&1; then eval "$(mise activate zsh)"; fi
if command -v direnv >/dev/null 2>&1; then eval "$(direnv hook zsh)"; fi
if command -v zoxide >/dev/null 2>&1; then eval "$(zoxide init zsh)"; fi
if command -v fzf >/dev/null 2>&1; then source <(fzf --zsh); fi
if command -v starship >/dev/null 2>&1; then eval "$(starship init zsh)"; fi
# <<< mac-dev-bootstrap <<<
BLOCK
)

touch "$ZSHRC"
if grep -qF "$MARKER_BEGIN" "$ZSHRC"; then
  # Replace existing block (everything between markers, inclusive)
  tmp="$(mktemp)"
  awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" -v block="$MANAGED_BLOCK" '
    $0 == begin { print block; skip=1; next }
    $0 == end   { skip=0; next }
    !skip       { print }
  ' "$ZSHRC" > "$tmp"
  mv "$tmp" "$ZSHRC"
else
  # Append new block
  printf '\n%s\n' "$MANAGED_BLOCK" >> "$ZSHRC"
fi

# Activate mise for this session (bash, since this script runs under bash)
eval "$(mise activate bash)" >/dev/null 2>&1 || true

# Runtimes (mise) — `mise use -g` installs and sets as global in one step
log "🧰 Installing runtimes via mise..."
mise use -g node@24
mise use -g python@3.12
mise use -g terraform@latest

log "📦 Enabling pnpm via corepack..."
corepack enable pnpm || true

# Colima
if colima status >/dev/null 2>&1; then
  echo "✅ Colima is already running."
elif ask_yn "Start Colima (Docker runtime) now?" "Y"; then
  CPU="${COLIMA_CPU:-$(ask "Colima CPU cores" "4")}"
  MEM="${COLIMA_MEM:-$(ask "Colima memory (GB)" "8")}"
  DISK="${COLIMA_DISK:-$(ask "Colima disk (GB)" "60")}"
  log "🐳 Starting Colima..."
  colima start --cpu "$CPU" --memory "$MEM" --disk "$DISK" || true
fi

# mkcert
if ask_yn "Install local HTTPS root CA with mkcert?" "Y"; then
  log "🔐 Installing mkcert local CA..."
  mkcert -install || true
fi

# Git identity
GIT_NAME="$(git config --global user.name 2>/dev/null || true)"
GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
if ask_yn "Configure global Git identity (user.name / user.email)?" "Y"; then
  GIT_NAME="$(ask "Git user.name" "$GIT_NAME")"
  GIT_EMAIL="$(ask "Git user.email" "$GIT_EMAIL")"
  [[ -n "$GIT_NAME"  ]] && git config --global user.name "$GIT_NAME"
  [[ -n "$GIT_EMAIL" ]] && git config --global user.email "$GIT_EMAIL"
  git config --global init.defaultBranch main
  git config --global pull.rebase true
fi

# SSH + GitHub registration (via gh)
if ask_yn "Set up SSH key for GitHub and register it using gh?" "Y"; then
  log "🔑 Setting up SSH for GitHub..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  KEY_PATH="$HOME/.ssh/id_ed25519"
  PUB_PATH="$KEY_PATH.pub"

  if [[ ! -f "$KEY_PATH" ]]; then
    DEFAULT_COMMENT="${GIT_EMAIL:-}"
    COMMENT="$(ask "SSH key comment (email/label)" "${DEFAULT_COMMENT:-mac-dev-bootstrap}")"
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "$COMMENT"
  fi

  SSH_CONFIG="$HOME/.ssh/config"
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"

  if ! grep -qE '^\s*Host\s+github\.com\s*$' "$SSH_CONFIG"; then
    cat >> "$SSH_CONFIG" <<'EOF'

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
  fi

  # Add to keychain/agent (best-effort, idempotent)
  ssh-add --apple-use-keychain "$KEY_PATH" >/dev/null 2>&1 || true

  # gh auth
  if ! gh auth status >/dev/null 2>&1; then
    log "🐙 Logging into GitHub via gh..."
    gh auth login --git-protocol ssh --web
  fi

  # Deduplicate by fingerprint
  LOCAL_FP="$(ssh-keygen -lf "$PUB_PATH" | awk '{print $2}')"
  if gh ssh-key list 2>/dev/null | awk '{print $2}' | grep -q "$LOCAL_FP"; then
    echo "✅ GitHub already has this SSH key ($LOCAL_FP)."
  else
    TITLE="$(ask "GitHub SSH key title" "$(hostname)-$(date +%Y-%m)")"
    gh ssh-key add "$PUB_PATH" --title "$TITLE"
  fi

  log "🔎 Testing GitHub SSH..."
  ssh -T git@github.com || true
fi

# VS Code Settings Sync
if ask_yn "Configure VS Code Settings Sync?" "Y"; then
  "$SCRIPT_DIR/vscode-settings-sync.sh" || true
fi

# macOS defaults
if ask_yn "Apply macOS developer defaults (Finder/Dock/keys)?" "Y"; then
  "$SCRIPT_DIR/macos-defaults.sh" || true
fi

# Security hardening
if ask_yn "Apply basic security settings (firewall, stealth mode)?" "N"; then
  log "🔐 Applying security settings (sudo required)..."
  sudo -v
  "$SCRIPT_DIR/security.sh" || true
fi

log "🧹 Cleaning up..."
brew cleanup || true

log "✅ Done. Restart your terminal to pick up shell changes."

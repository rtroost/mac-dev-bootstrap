# mac-dev-bootstrap

Opinionated, idempotent macOS setup for software development. One command gets you from a fresh Mac to a fully configured dev environment.

## What's included

| Category | Tools |
|---|---|
| **CLI essentials** | git, gh, wget, jq, ripgrep, fd, eza, bat, fzf, zoxide, direnv, starship, httpie, lazygit, git-delta, stow |
| **Runtimes** (via mise) | Node.js 24, Python 3.12, Terraform |
| **Node** | corepack + pnpm |
| **Containers** | Colima, Docker, docker-buildx, docker-compose |
| **Infra / K8s** | Azure CLI, Helm, kubectl, k9s |
| **Local HTTPS** | mkcert + nss |
| **GUI apps** | VS Code, Claude, iTerm2, Rectangle, Tailscale, Microsoft Remote Desktop |
| **Shell** | zsh with mise, direnv, zoxide, fzf key bindings, starship prompt |

## Prerequisites

- macOS (Apple Silicon or Intel)
- An internet connection
- That's it — the script installs everything else, including Xcode Command Line Tools (via Homebrew)

## Quick start

### One-liner (interactive)

```bash
curl -fsSL https://raw.githubusercontent.com/rtroost/mac-dev-bootstrap/main/install.sh | bash
```

### From a clone

```bash
git clone https://github.com/rtroost/mac-dev-bootstrap.git
cd mac-dev-bootstrap
chmod +x *.sh
./bootstrap.sh
```

### Non-interactive (CI / automated)

```bash
NONINTERACTIVE=1 ./bootstrap.sh
```

Or with the remote installer:

```bash
curl -fsSL https://raw.githubusercontent.com/rtroost/mac-dev-bootstrap/main/install.sh \
  | NONINTERACTIVE=1 bash
```

## What happens

`bootstrap.sh` runs through each section interactively (unless `NONINTERACTIVE=1`):

1. Installs **Homebrew** (if missing)
2. Installs all packages from the **Brewfile**
3. Configures **zsh** integrations (idempotent managed block in `~/.zshrc`)
4. Installs **runtimes** via mise (Node.js, Python, Terraform)
5. Enables **pnpm** via corepack
6. Optionally starts **Colima** (Docker runtime) with configurable CPU/memory/disk
7. Optionally installs a local **HTTPS root CA** via mkcert
8. Optionally configures **Git identity** and sensible defaults (`init.defaultBranch main`, `pull.rebase true`)
9. Optionally sets up an **SSH key** (ed25519) and registers it with GitHub via `gh`
10. Optionally configures **VS Code Settings Sync** by enabling `settingsSync.keybindingsPerPlatform` in VS Code user settings (sign in once to pull extensions, settings, keybindings)
11. Optionally applies **macOS developer defaults** (see below)
12. Optionally applies **security hardening** (see below)

### macOS defaults (`macos-defaults.sh`)

- Fast key repeat and short initial delay
- Finder: show hidden files, path bar, status bar; default to column view
- Avoid `.DS_Store` on network and USB drives
- Dock: auto-hide with no delay
- Screenshots: saved to `~/Screenshots` as PNG, no window shadow

### Security hardening (`security.sh`)

- Enable application firewall and stealth mode
- Disable guest account
- Require password immediately after sleep/screen saver
- Check FileVault status (warns if disabled)

## After installation

1. **Restart your terminal** (or `source ~/.zshrc`) to pick up shell changes
2. **Open VS Code** and sign in to Settings Sync (`Cmd+Shift+P` → "Settings Sync: Turn On...")
3. **Verify Docker** with `docker info` (if you started Colima)

## Re-running

The script is designed to be idempotent. You can safely re-run it after updating the repo — it will skip steps that are already complete and only apply changes. The `.zshrc` managed block is replaced on every run, so new integrations are picked up automatically.

## Customisation

| File | Purpose |
|---|---|
| `Brewfile` | Add or remove Homebrew packages and casks |
| `bootstrap.sh` | Change mise runtimes, add new setup sections |
| `macos-defaults.sh` | Tweak Finder, Dock, keyboard, screenshot preferences |
| `security.sh` | Adjust security hardening settings |
| `vscode-settings-sync.sh` | VS Code Settings Sync configuration |

## Project structure

```
.
├── install.sh                 # Remote installer entrypoint (curl | bash)
├── bootstrap.sh               # Main orchestrator — runs everything
├── Brewfile                   # Homebrew packages and casks
├── macos-defaults.sh          # macOS system preferences
├── security.sh                # Security hardening (requires sudo)
├── vscode-settings-sync.sh    # VS Code Settings Sync setup
├── .editorconfig              # Editor formatting rules
└── .github/workflows/
    └── validate.yml           # CI: shellcheck + Brewfile validation
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `NONINTERACTIVE` | `0` | Set to `1` to skip all prompts (uses defaults) |
| `COLIMA_CPU` | (asks) | CPU cores for Colima |
| `COLIMA_MEM` | (asks) | Memory in GB for Colima |
| `COLIMA_DISK` | (asks) | Disk in GB for Colima |
| `BRANCH` | `main` | Branch to use with remote installer |
| `REF` | (none) | Specific commit/tag to use with remote installer |

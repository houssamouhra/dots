#!/bin/sh

set -eu

# Configuration
DOTS_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
SUCKLESS_DIR="$HOME/.suckless"

DWM_REPO="git@github.com:houssamouhra/dwm.git"
ST_REPO="git@github.com:houssamouhra/st.git"
DMENU_REPO="git@github.com:houssamouhra/dmenu.git"
DWMBLOCKS_REPO="git@github.com:houssamouhra/dwmblocks.git"

# Colors
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  CYAN=''
  NC=''
fi

# Helpers
info() {
  printf "${BLUE}::${NC} %s\n" "$1"
}

success() {
  printf "${GREEN}✓${NC} %s\n" "$1"
}

warn() {
  printf "${YELLOW}!${NC} %s\n" "$1"
}

error() {
  printf "${RED}✗${NC} %s\n" "$1" >&2
}

# Preflight
if [ "$(id -u)" -eq 0 ]; then
  error "Run this script as a regular user, not root."
  exit 1
fi

for cmd in git make sudo stow; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "$cmd is required."
    exit 1
  fi
done

# Clone suckless repositories
info "Creating suckless directory..."

mkdir -p "$SUCKLESS_DIR"

clone_repo() {
  repo_name=$1
  repo_url=$2
  repo_dir="$SUCKLESS_DIR/$repo_name"

  if [ -d "$repo_dir/.git" ]; then
    warn "$repo_name already cloned. Skipping."
    return 0
  fi

  if [ -e "$repo_dir" ]; then
    error "$repo_dir exists but is not a Git repository."
    return 1
  fi

  info "Cloning $repo_name..."

  git clone "$repo_url" "$repo_dir"

  success "$repo_name cloned."
}

clone_repo dwm "$DWM_REPO"
clone_repo st "$ST_REPO"
clone_repo dmenu "$DMENU_REPO"
clone_repo dwmblocks "$DWMBLOCKS_REPO"

# Build and install suckless software
build_suckless() {
  repo_name=$1
  repo_dir="$SUCKLESS_DIR/$repo_name"

  info "Building $repo_name..."

  if [ ! -f "$repo_dir/Makefile" ]; then
    error "Makefile not found in $repo_dir"
    return 1
  fi

  (
    cd "$repo_dir"
    sudo make clean install
  )

  success "$repo_name installed."
}

build_suckless dwm
build_suckless st
build_suckless dmenu
build_suckless dwmblocks

# GNU Stow
info "Stowing dotfiles..."

cd "$DOTS_DIR"

stow -t "$HOME" .

success "Dotfiles stowed."

# Finished
printf "\n"
printf "${GREEN}========================================${NC}\n"
printf "${GREEN}         SETUP COMPLETED                ${NC}\n"
printf "${GREEN}========================================${NC}\n"

printf "\n"
info "Completed:"
printf "  - Cloned suckless repositories\n"
printf "  - Built and installed dwm, dwmblocks, st and dmenu\n"
printf "  - Stowed dotfiles via GNU Stow\n"

printf "\n"
info "Suckless repositories:"
printf "  %s\n" "$SUCKLESS_DIR/dwm"
printf "  %s\n" "$SUCKLESS_DIR/st"
printf "  %s\n" "$SUCKLESS_DIR/dmenu"
printf "  %s\n" "$SUCKLESS_DIR/dwmblock"

printf "\n"
warn "Review your OpenRC services and enable the ones you need."
printf "  sudo rc-service bluetoothd start\n"
printf "  sudo rc-service elogind start\n"
printf "  sudo rc-service connmand start\n"

warn "A reboot is recommended after the installation."

printf "\n"

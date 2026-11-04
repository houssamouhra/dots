#!/bin/sh

set -eu

# =============================================================================
# Configuration
# =============================================================================

DOTS_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
SUCKLESS_DIR="$HOME/.suckless"

DWM_REPO="https://github.com/houssamouhra/dwm.git"
ST_REPO="https://github.com/houssamouhra/st.git"
DMENU_REPO="https://github.com/houssamouhra/dmenu.git"

# =============================================================================
# Colors
# =============================================================================

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

# =============================================================================
# Cleanup
# =============================================================================

TMP_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup 0
trap 'exit 130' INT
trap 'exit 143' TERM

# =============================================================================
# Preflight
# =============================================================================

if [ "$(id -u)" -eq 0 ]; then
  error "Run this script as a regular user, not root."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  error "sudo is required."
  exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
  error "This script requires an Artix Linux installation."
  exit 1
fi

info "Checking pacman lock..."

while [ -f /var/lib/pacman/db.lck ]; do
  warn "Waiting for pacman..."
  sleep 2
done

# =============================================================================
# System update
# =============================================================================

info "Updating system..."

sudo pacman -Syu --noconfirm

success "System updated."

# =============================================================================
# Install paru
# =============================================================================

if ! command -v paru >/dev/null 2>&1; then

  info "Installing paru dependencies..."

  sudo pacman -S --needed --noconfirm \
    git \
    base-devel

  info "Cloning paru..."

  git clone https://aur.archlinux.org/paru.git \
    "$TMP_DIR/paru"

  info "Building paru..."

  (
    cd "$TMP_DIR/paru"
    makepkg -si --noconfirm
  )

  success "paru installed."

else
  success "paru is already installed."
fi

# =============================================================================
# Official repository packages
# =============================================================================

install_pacman() {
  for pkg in "$@"; do

    if pacman -Qq "$pkg" >/dev/null 2>&1; then
      printf "${CYAN}○${NC} %s already installed\n" "$pkg"
      continue
    fi

    info "Installing $pkg..."

    sudo pacman -S --needed --noconfirm "$pkg"

  done
}

info "Installing official packages..."

install_pacman \
  git \
  openssh \
  pacman-contrib \
  sudo \
  base-devel \
  zsh \
  foot \
  tmux \
  zoxide \
  bat \
  eza \
  fd \
  ripgrep \
  fzf \
  hyperfine \
  lazygit \
  serie \
  git-delta \
  github-cli \
  lazydocker \
  docker \
  dust \
  jq \
  keychain \
  tealdeer \
  trash-cli \
  pgcli \
  atac \
  duf \
  pass \
  fnm \
  uv \
  btop \
  imagemagick \
  fastfetch \
  stow \
  ttyper \
  cmatrix \
  neovim \
  pipewire-openrc \
  pipewire-pulse-openrc \
  wireplumber-openrc \
  wiremix \
  pamixer \
  ffmpeg \
  yt-dlp \
  mpv \
  imv \
  cava \
  mpd \
  mpc \
  playerctl \
  rmpc \
  elogind-openrc \
  connman-openrc \
  wpa_supplicant-openrc \
  adwaita-icon-theme \
  brightnessctl \
  yazi \
  python-sh \
  zathura \
  zathura-pdf-mupdf \
  ttf-cascadia-code \
  ttf-jetbrains-mono-nerd \
  noto-fonts \
  noto-fonts-emoji \
  noto-fonts-cjk \
  ttf-liberation \
  ttf-dejavu \
  bluez-openrc \
  bluez-openrc \
  bluez-utils \
  bluetui \
  xdg-user-dirs \
  man-pages \
  man-db \
  7zip \
  unzip \
  zip \
  dosfstools \
  exfatprogs \
  ntfs-3g \
  telegram-desktop \
  libnotify \
  pkgconf \
  imlib2 \
  libx11 \
  libxft \
  libxinerama \
  libxrender \
  libxext \
  xlibre-meta \
  xlibre-xserver \
  xlibre-input-libinput \
  xorg-xinit \
  xorg-xauth \
  xorg-xrandr \
  xorg-xset \
  xorg-xprop \
  xorg-xrdb \
  xorg-xmodmap \
  xorg-setxkbmap \
  xorg-xkbcomp \
  xclip \
  xsel \
  xdotool \
  xautolock \
  autorandr \
  xwallpaper \
  xcolor \
  xsct \
  xcompmgr \
  dunst \
  clipmenu

success "Official packages installed."

# =============================================================================
# AUR packages
# =============================================================================

install_aur() {
  for pkg in "$@"; do

    if pacman -Qq "$pkg" >/dev/null 2>&1; then
      printf "${CYAN}○${NC} %s already installed\n" "$pkg"
      continue
    fi

    info "Installing AUR package: $pkg..."

    paru -S --needed --noconfirm "$pkg"

  done
}

info "Installing AUR packages..."

install_aur \
  zen-browser-bin \
  zsh-patina-bin \
  spotify \
  bibata-cursor-theme \
  ghgrab-bin \
  diffnav \
  lazysql \
  mycli \
  maplemono-nf \
  dislocker-mbedtls3

success "AUR packages installed."

# =============================================================================
# Install Batsignal
# =============================================================================

if ! command -v batsignal >/dev/null 2>&1; then

  info "Installing Batsignal..."

  curl -fsSL \
    "https://github.com/houssamouhra/batsignal/archive/refs/tags/1.8.1.tar.gz" \
    -o "$TMP_DIR/batsignal.tar.gz"

  tar -xzf "$TMP_DIR/batsignal.tar.gz" -C "$TMP_DIR"

  (
    cd "$TMP_DIR/batsignal-1.8.1"

    make CFLAGS_EXTRA="-pedantic -Wall -Wextra -Werror -Wno-error=unused-result -Wno-unused-parameter -Os"

    sudo make install
  )

  success "Batsignal installed."

else
  success "Batsignal already installed."
fi

# =============================================================================
# Install statcode
# =============================================================================

if ! command -v statcode >/dev/null 2>&1; then

  info "Installing statcode..."

  curl -fsSL \
    "https://github.com/houssamouhra/statcode/releases/download/v2.1.0/statcode-2.1.0-linux-x86_64.tar.gz" \
    -o "$TMP_DIR/statcode.tar.gz"

  tar -xzf "$TMP_DIR/statcode.tar.gz" -C "$TMP_DIR"

  if [ ! -d "$TMP_DIR/statcode-dist.dist" ]; then
    error "Unexpected statcode archive layout."
    exit 1
  fi

  sudo install -d /usr/lib/statcode /usr/bin

  sudo cp -a "$TMP_DIR/statcode-dist.dist/." /usr/lib/statcode/

  sudo ln -sfn /usr/lib/statcode/statcode /usr/local/bin/statcode

  success "statcode installed."

else
  success "statcode already installed."
fi

# =============================================================================
# Clone suckless repositories
# =============================================================================

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

# =============================================================================
# Build and install suckless software
# =============================================================================

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

# =============================================================================
# GNU Stow
# =============================================================================

info "Stowing dotfiles..."

cd "$DOTS_DIR"

stow -t "$HOME" .

success "Dotfiles stowed."

# =============================================================================
# Finished
# =============================================================================

printf "\n"
printf "${GREEN}========================================${NC}\n"
printf "${GREEN}       INSTALLATION COMPLETED           ${NC}\n"
printf "${GREEN}========================================${NC}\n"

printf "\n"
info "Installed:"
printf "  - Official repository packages\n"
printf "  - AUR packages\n"
printf "  - Batsignal and statcode\n"
printf "  - dwm, st and dmenu\n"
printf "  - Dotfiles via GNU Stow\n"

printf "\n"
info "Suckless repositories:"
printf "  %s\n" "$SUCKLESS_DIR/dwm"
printf "  %s\n" "$SUCKLESS_DIR/st"
printf "  %s\n" "$SUCKLESS_DIR/dmenu"

printf "\n"
warn "Review your OpenRC services and enable the ones you need."
printf "sudo rc-service bluetoothd start"
printf "sudo rc-service elogind start"
printf "sudo rc-service connmand start"
warn "A reboot is recommended after the installation."

printf "\n"

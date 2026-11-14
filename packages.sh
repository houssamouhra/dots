#!/bin/sh

set -eu

# Configuration
TMP_DIR=$(mktemp -d)

# Set these before running the script.
XLIBRE_KEY_URL="https://xlibre-artix.github.io/xlibre-artixlinux.asc"
XLIBRE_KEY_ID="2AFFCD7B42ADD2E7"

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

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup 0
trap 'exit 130' INT
trap 'exit 143' TERM

# Preflight
if [ "$(id -u)" -eq 0 ]; then
  error "Run this script as a regular user, not root."
  exit 1
fi

for cmd in sudo pacman curl git awk grep tar makepkg; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "$cmd is required."
    exit 1
  fi
done

info "Checking pacman lock..."

while [ -f /var/lib/pacman/db.lck ]; do
  warn "Waiting for pacman..."
  sleep 2
done

# Configure XLibre repository
configure_xlibre() {
  info "Importing XLibre signing key..."

  curl -fsSL "$XLIBRE_KEY_URL" \
    -o "$TMP_DIR/xlibre-artixlinux.asc"

  sudo pacman-key --add "$TMP_DIR/xlibre-artixlinux.asc"

  info "Verifying XLibre signing key fingerprint..."

  sudo pacman-key --finger "$XLIBRE_KEY_ID"
  sudo pacman-key --lsign-key "$XLIBRE_KEY_ID"

  success "XLibre signing key imported."

  info "Configuring XLibre repository..."

  if [ ! -f /etc/pacman.conf ]; then
    error "/etc/pacman.conf not found."
    return 1
  fi

  if ! grep -q '^\[system\]' /etc/pacman.conf ||
    ! grep -q '^\[world\]' /etc/pacman.conf; then
    error "Could not find [system] or [world] in pacman.conf."
    return 1
  fi

  awk '
    BEGIN {
      skip = 0
      inserted = 0
      system_seen = 0
      world_seen = 0
    }

    /^\[system\]$/ {
      system_seen = NR
    }

    /^\[xlibre-stable\]$/ {
      skip = 1
      next
    }

    skip && /^\[/ {
      skip = 0
    }

    !skip && /^\[world\]$/ {
      world_seen = NR

      if (!inserted) {
        print "[xlibre-stable]"
        print "Server = https://github.com/xlibre-artix/stable/releases/download/$arch"
        print ""
        inserted = 1
      }
    }

    !skip {
      print
    }

    END {
      if (!system_seen || !world_seen ||
          system_seen >= world_seen || !inserted) {
        exit 1
      }
    }
  ' /etc/pacman.conf >"$TMP_DIR/pacman.conf"

  sudo install -o root -g root -m 644 \
    "$TMP_DIR/pacman.conf" \
    /etc/pacman.conf

  success "XLibre repository configured."
}

configure_xlibre

# System update
info "Refreshing package databases and updating system..."

sudo pacman -Syyu

success "System updated."

# Install paru
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

# Official repository packages
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
  xcompmgr \
  dunst \
  clipmenu

success "Official packages installed."

# Install XLibre
info "Installing XLibre..."

if pacman -Qq xlibre-meta >/dev/null 2>&1; then
  success "XLibre is already installed."
else
  info "Installing XLibre meta package..."

  sudo pacman -S xlibre-meta

  success "XLibre installed."
fi

# AUR packages
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
  xsct \
  i3lock-color \
  maplemono-nf \
  dislocker-mbedtls3

success "AUR packages installed."

# Install Batsignal
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

# Install Statcode
if ! command -v statcode >/dev/null 2>&1; then
  info "Installing Statcode..."

  curl -fsSL \
    "https://github.com/houssamouhra/statcode/releases/download/v2.1.0/statcode-2.1.0-linux-x86_64.tar.gz" \
    -o "$TMP_DIR/statcode.tar.gz"

  tar -xzf "$TMP_DIR/statcode.tar.gz" -C "$TMP_DIR"

  if [ ! -d "$TMP_DIR/statcode-dist.dist" ]; then
    error "Unexpected statcode archive layout."
    exit 1
  fi

  sudo install -d /usr/lib/statcode /usr/local/bin

  sudo cp -a "$TMP_DIR/statcode-dist.dist/." /usr/lib/statcode/

  sudo ln -sfn /usr/lib/statcode/statcode /usr/local/bin/statcode

  success "Statcode installed."
else
  success "Statcode already installed."
fi

# Finished
printf "\n"
printf "${GREEN}========================================${NC}\n"
printf "${GREEN}       PACKAGE INSTALLATION COMPLETED   ${NC}\n"
printf "${GREEN}========================================${NC}\n"

printf "\n"
info "Installed:"
printf "  - Official repository packages\n"
printf "  - XLibre\n"
printf "  - AUR packages\n"
printf "  - Batsignal\n"
printf "  - Statcode\n"

printf "\n"
warn "Review your OpenRC services and enable the ones you need."
printf "  sudo rc-service bluetoothd start\n"
printf "  sudo rc-service elogind start\n"
printf "  sudo rc-service connmand start\n"

warn "A reboot is recommended after installation."
printf "\n"

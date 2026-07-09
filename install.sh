#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -t 1 ]; then
  BOLD=$'\033[1m'; RESET=$'\033[0m'
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  BLUE=$'\033[34m'; MAGENTA=$'\033[35m'; CYAN=$'\033[36m'
else
  BOLD=""; RESET=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""
fi

log_info() { printf '%s[*]%s %s\n' "$BLUE" "$RESET" "$*"; }
log_ok()   { printf '%s[+]%s %s\n' "$GREEN" "$RESET" "$*"; }
log_warn() { printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
section()  { printf '\n%s%s==>%s %s%s%s\n' "$BOLD" "$MAGENTA" "$RESET" "$BOLD" "$*" "$RESET"; }

banner() {
  printf '%s' "$CYAN"
  cat <<'ART'
   ░▒▓█▓▒░▒▓███████▓▒░▒▓███████▓▒░░▒▓████████▓▒░
░▒▓████▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
   ░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░      ░▒▓█▓▒░
   ░▒▓█▓▒░▒▓███████▓▒░▒▓███████▓▒░      ░▒▓█▓▒░
   ░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░     ░▒▓█▓▒░
   ░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░    ░▒▓█▓▒░
   ░▒▓█▓▒░▒▓███████▓▒░▒▓███████▓▒░     ░▒▓█▓▒░
ART
  printf '%s%si3-config installer%s\n' "$RESET" "$BOLD" "$RESET"
}

PACMAN_PACKAGES=(
  i3-wm i3status-rust rofi dunst picom guake feh nemo
  otf-font-awesome ttf-fira-code zsh speedtest-cli
  iwd xss-lock
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol
  xorg-xinit dex ly
  papirus-icon-theme capitaine-cursors
  base-devel git
)

AUR_PACKAGES=(
  i3lock-color
  rofi-greenclip
  mictray
  neofetch-git
  qogir-gtk-theme
)

require_arch() {
  command -v pacman >/dev/null 2>&1 || {
    echo "This script only supports Arch Linux (pacman not found)." >&2
    exit 1
  }
}

require_git_repo() {
  git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "install.sh must be run from inside a git clone of this repo." >&2
    exit 1
  }
}

install_pacman_packages() {
  sudo pacman -S --needed "${PACMAN_PACKAGES[@]}"
}

ensure_yay() {
  command -v yay >/dev/null 2>&1 && return
  log_info "yay not found, bootstrapping it from the AUR..."
  local build_dir="$HOME/.cache/aur-builds/yay"
  mkdir -p "$(dirname "$build_dir")"
  if [ -d "$build_dir" ]; then
    git -C "$build_dir" pull
  else
    git clone https://aur.archlinux.org/yay.git "$build_dir"
  fi
  (cd "$build_dir" && makepkg -si --needed)
}

remove_conflicting_i3lock() {
  if pacman -Qi i3lock >/dev/null 2>&1; then
    log_info "Removing stock i3lock (conflicts with i3lock-color)..."
    sudo pacman -R --noconfirm i3lock ||
      log_warn "could not remove i3lock automatically; remove it manually before re-running"
  fi
}

install_aur_packages() {
  remove_conflicting_i3lock
  yay -S --needed "${AUR_PACKAGES[@]}"
}

deploy_dotfiles() {
  local backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
  local backed_up=0
  local file src dest
  while IFS= read -r -d '' file; do
    src="$REPO_DIR/$file"
    dest="$HOME/$file"
    if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
      continue
    fi
    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      mkdir -p "$(dirname "$backup_dir/$file")"
      mv "$dest" "$backup_dir/$file"
      backed_up=1
    fi
    ln -s "$src" "$dest"
    log_ok "linked ~/$file"
  done < <(git -C "$REPO_DIR" ls-files -z)
  [ "$backed_up" = 1 ] && log_warn "existing files backed up to $backup_dir"
}

ensure_projects_dir() {
  mkdir -p "$HOME/projects"
}

enable_services() {
  systemctl --user daemon-reload
  systemctl --user enable --now batteryWatcher.service
  log_ok "batteryWatcher.service enabled"
  # ly ships a per-tty template unit, not a plain ly.service (see ArchWiki:Ly) —
  # enable it on tty1 and disable the getty it replaces there.
  sudo systemctl disable getty@tty1.service ||
    log_warn "could not disable getty@tty1.service"
  sudo systemctl enable ly@tty1.service &&
    log_ok "ly@tty1.service enabled" ||
    log_warn "could not enable ly@tty1.service (check that the ly package installed correctly)"
}

spawn_if_missing() {
  local proc_name="$1"
  shift
  if pgrep -x "$proc_name" >/dev/null 2>&1; then
    log_info "$proc_name already running, skipping"
    return
  fi
  "$@" >/dev/null 2>&1 &
  disown 2>/dev/null || true
  log_ok "started $proc_name"
}

start_autostart_apps() {
  if [ -z "${DISPLAY:-}" ]; then
    log_warn "no active X session detected; autostart apps will start on next graphical login"
    return
  fi
  spawn_if_missing guake guake
  spawn_if_missing dunst dunst
  spawn_if_missing mictray mictray
  spawn_if_missing picom picom -b
  spawn_if_missing greenclip greenclip daemon
  spawn_if_missing xss-lock xss-lock --transfer-sleep-lock -- bash "$HOME/.config/i3lock/lock.sh"
  feh --bg-fill "$HOME/.images/wallpapers/wallpaper.jpg"
  log_ok "wallpaper set"
}

reload_i3() {
  if [ -n "${DISPLAY:-}" ] && command -v i3-msg >/dev/null 2>&1; then
    i3-msg reload >/dev/null 2>&1 && log_ok "i3 config reloaded" || log_warn "i3-msg reload failed"
  fi
}

final_message() {
  printf '\n%s%s✓ Setup complete.%s\n' "$BOLD" "$GREEN" "$RESET"
  if [ -z "${DISPLAY:-}" ]; then
    log_info "reboot (for the ly login manager) or log in graphically to start everything"
  fi
}

main() {
  banner
  require_arch
  require_git_repo

  section "Installing official packages"
  install_pacman_packages

  section "Installing AUR packages"
  ensure_yay
  install_aur_packages

  section "Deploying dotfiles"
  deploy_dotfiles
  ensure_projects_dir

  section "Enabling services"
  enable_services

  section "Starting autostart apps"
  start_autostart_apps
  reload_i3

  final_message
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  echo "yay not found, bootstrapping it from the AUR..."
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
    echo "Removing stock i3lock (conflicts with i3lock-color)..."
    sudo pacman -R --noconfirm i3lock ||
      echo "warning: could not remove i3lock automatically; remove it manually before re-running"
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
    echo "linked ~/$file"
  done < <(git -C "$REPO_DIR" ls-files -z)
  [ "$backed_up" = 1 ] && echo "Existing files backed up to $backup_dir"
}

ensure_projects_dir() {
  mkdir -p "$HOME/projects"
}

enable_services() {
  systemctl --user daemon-reload
  systemctl --user enable --now batteryWatcher.service
  sudo systemctl enable ly.service
}

spawn_if_missing() {
  local proc_name="$1"
  shift
  if pgrep -x "$proc_name" >/dev/null 2>&1; then
    echo "$proc_name already running, skipping"
    return
  fi
  "$@" >/dev/null 2>&1 &
  disown 2>/dev/null || true
  echo "started $proc_name"
}

start_autostart_apps() {
  if [ -z "${DISPLAY:-}" ]; then
    echo "No active X session detected; autostart apps will start on next graphical login."
    return
  fi
  spawn_if_missing guake guake
  spawn_if_missing dunst dunst
  spawn_if_missing mictray mictray
  spawn_if_missing picom picom -b
  spawn_if_missing greenclip greenclip daemon
  spawn_if_missing xss-lock xss-lock --transfer-sleep-lock -- bash "$HOME/.config/i3lock/lock.sh"
  feh --bg-fill "$HOME/.images/wallpapers/wallpaper.jpg"
}

final_message() {
  echo
  echo "Setup complete."
  if [ -z "${DISPLAY:-}" ]; then
    echo "- Reboot (for the ly login manager) or log in graphically to start everything."
  fi
}

main() {
  require_arch
  require_git_repo
  install_pacman_packages
  ensure_yay
  install_aur_packages
  deploy_dotfiles
  ensure_projects_dir
  enable_services
  start_autostart_apps
  final_message
}

main "$@"

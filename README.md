# i3-config

Personal dotfiles for an **_i3-based_** Linux desktop, managed with `~/.config` as the repository root. Covers the window manager, status bar, launcher, notifications, compositor, terminal, editor, and a few helper scripts/services.

## Install

`./install.sh` automates everything below: installs all packages (official + AUR, via `yay` — bootstrapped automatically if missing), symlinks every tracked file from the clone into `$HOME` (backing up any conflicting existing files under `~/.dotfiles-backup/<timestamp>/`), enables the `batteryWatcher` and `ly` services, and starts the autostart apps (`guake`, `dunst`, `mictray`, `picom`, `greenclip`, `xss-lock`) immediately if you're already in an X session.

```sh
git clone <this-repo-url> ~/i3-config
cd ~/i3-config
./install.sh
```

Requires Arch Linux (`pacman`) and must be run from inside a git clone of this repo (not a bare copy of the files).

## Packages

The package lists `install.sh` installs, for reference (or manual install):

```sh
# official repos
sudo pacman -S i3-wm i3status-rust rofi dunst picom guake feh nemo \
  otf-font-awesome ttf-fira-code zsh speedtest-cli \
  iwd xss-lock \
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol \
  xorg-xinit dex ly papirus-icon-theme capitaine-cursors base-devel git

# AUR (via yay)
yay -S i3lock-color rofi-greenclip mictray neofetch-git qogir-gtk-theme
```

Notes(For manual installk):

- `rofi` must be installed before configuring this setup, as it is used for launching applications and managing clipboard history.
- `i3status-rust` is a Rust-based status bar that replaces the default `i3status`. It is configured via `i3status-rust/config.toml`.
- `rofi-greenclip` provides the `greenclip` binary (there's no separate `greenclip` package) — it's the clipboard manager that integrates with Rofi, configured via `rofi/config.rasi`.
- `i3lock/lock.sh` uses coloring/blur flags (`--ring-color`, `--insidever-color`, `--blur`, etc.) that only the [`i3lock-color`](https://github.com/Raymo111/i3lock-color) fork supports. Only install `i3lock-color` (AUR) — installing stock `i3lock` alongside/instead of it will make the lock script fail with missing-option errors.
- `gtk-3.0/settings.ini` pulls in three separate theme packages: `qogir-gtk-theme` (AUR, the GTK theme itself), `papirus-icon-theme` (icon theme), and `capitaine-cursors` (cursor theme).
- `ly` is a TUI login manager/greeter; `install.sh` only `enable`s it (not `--now`), so it takes over at the next reboot instead of disrupting your current session.
- Networking uses `iwd` directly, not NetworkManager — `i3/config` has its `nm-applet` autostart line commented out.

## Layout

| Path                                  | Purpose                                                                                                        |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `i3/config`                           | Window manager config: keybindings, workspaces, autostart                                                      |
| `i3status-rust/config.toml`           | Status bar blocks (window title, music, network, battery, etc.)                                                |
| `i3lock/lock.sh`                      | Screen locker invocation with custom colors, used on suspend and manual lock                                   |
| `rofi/config.rasi`                    | Application/window launcher theme and keybindings                                                              |
| `dunst/dunstrc`                       | Notification daemon configuration                                                                              |
| `picom/picom.conf`                    | Compositor: shadows, blur, fading                                                                              |
| `gtk-3.0/settings.ini`                | GTK theme, icon theme, cursor theme                                                                            |
| `nvim/`                               | Neovim config, built on LazyVim                                                                                |
| `guake/guake_prefs.cfg`               | Dropdown terminal preferences, exported from dconf (`{{HOME}}` templated, loaded via `dconf load` by `install.sh`) |
| `nemo/`                               | File manager settings (not tracked in this repo; local `~/.config/nemo` state)                                 |
| `neofetch/ascii`                      | Custom ASCII art for neofetch                                                                                  |
| `scripts/batteryWatcher.sh`           | Polls battery level and sends low-battery notifications                                                        |
| `systemd/user/batteryWatcher.service` | User service that runs the battery watcher on login                                                            |
| `.images/wallpapers/`                 | Wallpaper images — `wallpaper.jpg` (active) and `red.png` (alternate)                                          |
| `.xinitrc`                            | X session startup script — merges Xresources/keymaps, then `exec i3` (for `startx`; ly uses xsessions instead) |
| `.zshrc`                              | Zsh config, oh-my-zsh with the `robbyrussell` theme                                                            |
| `.zshenv`                             | Sources `~/.cargo/env` for every zsh shell                                                                     |
| `install.sh`                          | Installs all packages and symlinks every tracked file into `$HOME`                                             |

## Window manager (i3)

Base config generated by `i3-config-wizard` and extended from there. For everything not covered below (modes, container layout, marks, etc.), see the [official i3 User's Guide](https://i3wm.org/docs/userguide.html).

- `$mod+Return` — open Guake terminal
- `$mod+d` — Rofi run launcher
- `$mod+v` — Rofi clipboard history (`rofi -modi clipboard:greenclip print`)
- `$mod+Escape` — lock screen (`i3lock/lock.sh`)

- `$mod+Shift+minus` — move focused window to scratchpad
- `$mod+minus` — show/cycle scratchpad window

**System**

- `$mod+Shift+q` — kill focused window
- `$mod+Shift+c` — reload config
- `$mod+Shift+r` — restart i3 in place
- `$mod+Shift+e` — exit prompt (i3-nagbar)

**Look & feel:** `gaps inner 8`, `gaps outer 2`, `default_border none`.

**Autostart (`exec`/`exec_always` in `i3/config`), in order:**

1. `dex --autostart --environment i3` — run XDG autostart `.desktop` entries
2. `guake` — dropdown terminal
3. `feh --bg-fill` — set wallpaper
4. `dunst` — notification daemon
5. `mictray` — mic mute tray icon
6. `greenclip daemon` — clipboard history backend for Rofi
7. `xss-lock --transfer-sleep-lock -- i3lock/lock.sh` — lock screen on suspend
8. `picom -b` — compositor, started in daemon mode

## Wallpaper

`feh` sets the wallpaper on i3 startup, loading `~/.images/wallpapers/wallpaper.jpg` (kept in this repo). `red.png` is also tracked in the same folder as an alternate/spare wallpaper, not currently wired up to anything. Wallpaper credit: [metis-os/metis-wallpapers](https://github.com/metis-os/metis-wallpapers).

## Shell

`.zshrc` runs [oh-my-zsh](https://ohmyz.sh/) with the `robbyrussell` theme. `.zshenv` just sources `~/.cargo/env` so `cargo`/`rustup` binaries are on `PATH` in every shell, interactive or not.

## Status bar

`i3status-rust` with the `ctp-macchiato` theme and Awesome6 icons. Blocks include focused window title, a tea timer, Spotify controls, network, speedtest, volume, battery, CPU/load/memory, disk space (`~/projects`, `/home`, `/`), uptime, and clock.

## Battery watcher

`scripts/batteryWatcher.sh` polls `/sys/class/power_supply/BAT0` every 10 seconds while discharging and fires one desktop notification at 15% and an urgent one at 10% (re-armed when the charger is plugged in). On machines without a battery the service exits cleanly (`ConditionPathExists`). Enable it with:

```sh
# .config/systemd/user/batteryWatcher.service
systemctl --user enable --now batteryWatcher.service
```

## Usage

See [Install](#install) above — clone the repo and run `./install.sh` on an Arch-based i3 setup. Dependencies used across the configs include: `i3`, `i3lock-color`, `i3status-rust`, `rofi`, `dunst`, `picom`, `guake`, `greenclip`, `feh`, `mictray`, `iwd`, `neofetch`, PipeWire/`pactl`, and Neovim with `lazy.nvim`.

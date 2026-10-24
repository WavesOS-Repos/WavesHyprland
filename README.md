# WavesHyprland

Arch Linux Hyprland rice installer.

**Stack:** Hyprland (Lua) · Matugen · Wallfliper · Thunar · Relax GTK · Waybar · Rofi · wlogout · Hyprlock · Conky · qylock SDDM

## Usage

```bash
chmod +x install.sh scripts/*.sh
./install.sh           # menu
./install.sh --all     # full install
```

Run as a normal user; `sudo` is requested when needed.

## Commands

| Flag | Action |
|------|--------|
| `--all` | Full pipeline |
| `--yay` | Install yay |
| `--packages` | pacman.txt + aur.txt |
| `--backup` | Backup existing configs |
| `--configs` | Deploy `configs/` |
| `--wallfliper` | Deploy Wallfliper |
| `--themes` | Install from `themes/` |
| `--sddm` | qylock → `/usr/share/sddm/themes` + user helper |
| `--post` | chmod, seeds, default wallpaper |

## Before GitHub

**Read [BEFORE_GITHUB.md](BEFORE_GITHUB.md)** — what to copy into `configs/`, `themes/`, `sddm/`, `apps/`, `assets/`.

## Rules

- Matugen owns Kitty / Waybar / Rofi / Hypr borders  
- Thunar = GTK Relax + Hypr opacity rule  
- No Kitty `dark-theme.auto.conf`  
- Conky config under `configs/conky/`; fix autostart path to `$HOME`  

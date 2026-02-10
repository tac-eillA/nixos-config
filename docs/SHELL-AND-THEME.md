# Shell and Theme System

## Core Components

- WM: `niri`
- Bar: `waybar`
- Launcher: `walker`
- Notifications: `mako`
- Screen lock/idle: `swaylock` + `swayidle`
- Wallpaper: `swww`
- Dynamic colors: `pywal`

## Key Config Files

- `config/niri/config.kdl`
- `config/waybar/config.jsonc`
- `config/waybar/style.css`
- `config/walker/config.toml`
- `config/mako/config`
- `config/kitty/kitty.conf`
- `config/shell/bin/*`

## Shell Script Layer

Main entry scripts:

- `shell-menu`
- `shell-launcher`
- `shell-launch-or-focus`
- `shell-cmd-screenshot`
- `shell-cmd-screenrecord`
- `shell-set-wallpaper`
- `shell-apply-theme`
- `shell-waybar`
- `shell-snapshot`
- `shell-fingerprint`

## Shell Menu Additions

- `Create Snapshot`: creates a read-only Btrfs snapshot of the current root subvolume.
- `Restore Snapshot`: interactive path-level restore from a selected snapshot.
- `Fingerprint Setup`, `Fingerprint Verify`, `Fingerprint Remove`: helper actions around `fprintd` tools.

`Update + Rebuild` now attempts a pre-update snapshot first, then proceeds with flake update and rebuild.

## Snapshot Backend

- Root tool: `scripts/system-snapshot.sh` (run via `shell-snapshot`)
- Snapshot location: top-level Btrfs subvolume `@snapshots/root`
- Snapshot names: `YYYYmmdd-HHMMSS-<label>`
- Restore mode: safe path-level restore only (no full root rollback)

## Dynamic Wallpaper Theming

Flow:

1. set wallpaper (`shell-set-wallpaper`)
2. extract palette (`shell-apply-theme` via `wal`)
3. generate runtime theme files:
   - `/tmp/shell-waybar-theme.css`
   - `/tmp/shell-kitty-theme.conf`
   - `/tmp/shell-mako-theme.conf`
4. rebuild Waybar runtime CSS cache and reload UI components

## Wallpaper Sources

Scanned in this order:

1. `SHELL_WALLPAPER_DIR` (if set)
2. `~/.config/wallpapers`
3. `~/Pictures/wallpapers`
4. `~/Pictures/Wallpapers`

Best practice for repo-managed wallpapers:

- put files in `config/wallpapers`

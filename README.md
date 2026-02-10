# Artemis NixOS (Niri + Waybar + Walker)

Self-contained NixOS flake on `nixos-unstable` for host `artemis`.

This repo does not use Home Manager for dotfiles. User config is stored in this repo under `config/` and symlinked into `~/.config`.

## Quick start

Generate or refresh host variables first:

```bash
./scripts/bootstrap-variables.sh artemis
```

Then build/switch:

```bash
sudo nixos-rebuild switch --flake .#artemis
```

If needed, re-link user config files:

```bash
./scripts/link-configs.sh
```

## Repo location

This setup can live outside `/etc/nixos` (for example `~/nixos-config`).

Set the repo path in `hosts/<host>/variables.nix`:

```nix
paths = {
  repoRoot = "/home/<user>/nixos-config";
};
```

The shell helpers and user services read `paths.repoRoot` so rebuild/update helpers work from that location.

## Live ISO install (interactive)

From a NixOS live ISO, clone this repo and run:

```bash
sudo ./scripts/live-install.sh artemis
```

What it does:

- verifies you are in a live ISO + UEFI + root shell
- interactive disk partitioning (auto or manual)
- optional root LUKS setup
- formats and mounts Btrfs subvolume layout
- copies repo to target `/etc/nixos`
- optionally copies repo to your chosen runtime path (for example `~/nixos-config`)
- generates host `hardware-configuration.nix`
- writes host `variables.nix` interactively
- runs `nixos-install --flake ...`
- sets the user password in the installed system

Notes:

- It is destructive for auto partition mode.
- Host directory must exist in this repo (`hosts/<host>`).
- Current install layout assumes Btrfs root with `@`, `@home`, `@log` subvolumes.
- Live installer prompts for `paths.repoRoot` and can pre-copy the repo there before first boot.

## Repo map (what to edit)

- `flake.nix`:
  - Flake inputs, `nixosConfigurations`, language dev shells, and host variable injection
- `hosts/artemis/configuration.nix`:
  - Host module imports
  - Uses values from host `variables.nix` for hostname/user/profile wiring
- `hosts/artemis/variables.nix`:
  - Per-host user/machine values, including `paths.repoRoot` (the file you edit most often)
- `hosts/variables.example.nix`:
  - Template for new hosts
- `hosts/artemis/hardware-configuration.nix`:
  - Hardware kernel module hints only
- `modules/base.nix`:
  - Core defaults (Nix settings, locale, timezone, shell defaults, session vars)
- `modules/boot-storage.nix`:
  - Generic boot/disk logic that reads host storage values from `variables.nix`
- `modules/services-core.nix`:
  - Core services (audio, printing, bluetooth, docker, tailscale, fwupd)
- `modules/packages-core.nix`:
  - Base package set and fonts (includes `opencode` CLI)
- `modules/desktop-niri.nix`:
  - Niri desktop stack package/module wiring
- `modules/shell-suite.nix`:
  - Shell utility layer packages + user services/timers
- `modules/profile-framework13-amd.nix`:
  - Framework 13 laptop profile settings
- `modules/profile-nvidia-desktop.nix`:
  - NVIDIA desktop profile settings
- `modules/profile-gaming.nix`:
  - Gaming and Steam profile
- `config/niri/config.kdl`:
  - Window manager layout, grouped binds, grouped autostart
- `config/waybar/config.jsonc` and `config/waybar/style.css`:
  - Top bar modules and styling (module names are grouped and explicit)
- `config/walker/config.toml`:
  - Launcher behavior and provider prefixes
- `config/git/config` and `config/git/ignore`:
  - Global Git behavior, aliases, and ignore patterns (via XDG config)
- `config/shell/bin/*`:
  - Shell helper scripts (menu, screenshot, recording, wallpaper, updates, theming)
- `config/zsh/.zshrc`:
  - Shell prompt, aliases, nix rebuild helpers
- `config/nvim/*`, `config/tmux/tmux.conf`, `config/doom/*`:
  - Editor and terminal tooling config
- `scripts/bootstrap-variables.sh`:
  - Interactive generator/editor for per-host `variables.nix`
- `scripts/live-install.sh`:
  - Full interactive live ISO installer (partition, mount, variables, install)

## How config linking works

- `scripts/link-configs.sh` symlinks every directory/file in repo `config/` to `~/.config/<name>`.
- It is run by `systemd --user` service `link-configs` from `modules/dotfiles-link.nix`.
- Existing non-symlink targets are moved to a timestamped backup before link creation.

## Shell suite overview

The shell layer is implemented in `modules/shell-suite.nix` and `config/shell/bin/*`.

Core scripts:

- `shell-menu`:
  - Main command menu (apps, wallpaper, screenshot, recording, updates, power)
- `shell-launcher`:
  - Starts walker/elephant services and opens Walker
- `shell-cmd-screenshot`:
  - Screenshot flow (`smart|region|full` + `satty|clipboard`)
- `shell-cmd-screenrecord`:
  - Toggle recording with `wf-recorder`
- `shell-screenrecord-indicator`:
  - JSON state for Waybar recording indicator
- `shell-update-check` and `shell-update-indicator`:
  - Check nixpkgs lock drift and render bar status
- `shell-battery-monitor`:
  - Low battery notification check (timer-driven)
- `shell-set-wallpaper`, `shell-next-wallpaper`, `shell-apply-theme`:
  - Wallpaper cycling and dynamic theme generation
- `shell-waybar`:
  - Starts Waybar with rendered style (theme overrides + base CSS)

## Git configuration

Git is configured through XDG files in this repo:

- `config/git/config`
- `config/git/ignore`

After linking, these are available at:

- `~/.config/git/config`
- `~/.config/git/ignore`

Set your identity once if needed:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Useful aliases from this config:

- `git st` (short status)
- `git lg` (graph log)
- `git l1` (last commit with stats)
- `git aa` (add all)
- `git unstage` (restore staged)

Waybar module naming is intentionally descriptive:

- `custom/shell-menu`
- `custom/system-update`
- `custom/screen-recording`

Niri bind ordering is grouped by task:

- launch/menu
- session controls
- audio/brightness/media
- window and navigation
- workspace operations
- capture/recording

## Dynamic wallpaper theming

Theme is generated from wallpaper colors using `pywal`.

Flow:

1. `shell-set-wallpaper` sets wallpaper via `swww`.
2. `shell-apply-theme` runs `wal` and extracts colors.
3. Runtime theme files are generated:
   - `/tmp/shell-waybar-theme.css`
   - `/tmp/shell-kitty-theme.conf`
   - `/tmp/shell-mako-theme.conf`
4. Waybar rendered style is rebuilt at:
   - `${XDG_CACHE_HOME:-~/.cache}/shell/waybar-style.css`
5. Waybar and Mako are reloaded.

Wallpaper source order:

- `SHELL_WALLPAPER_DIR` (if set)
- `~/.config/wallpapers`
- `~/Pictures/wallpapers`
- `~/Pictures/Wallpapers`

## Key binds (Niri)

Primary shell actions from `config/niri/config.kdl`:

- `Mod+D`: open launcher
- `Mod+Space`: open shell menu
- `Mod+Shift+W`: next wallpaper + re-theme
- `Print`: screenshot with annotation flow
- `Ctrl+Print`: full screenshot to clipboard
- `Mod+Shift+S`: region screenshot to clipboard
- `Mod+Shift+R`: toggle screen recording

## Profile toggles

Profile switches are set per host in `hosts/<host>/variables.nix`:

```nix
profiles = {
  framework13 = true;
  nvidiaDesktop = false;
  gaming = true;
};
```

Desktop example:

```nix
profiles = {
  framework13 = false;
  nvidiaDesktop = true;
  gaming = true;
};
```

## Storage and boot configuration

Boot/disk logic is generic in `modules/boot-storage.nix`.

Per-machine values are set in host variables under `storage` (UUIDs, PARTUUID, and subvol names).

Current host example:

```nix
storage = {
  rootFsUuid = "e9a2587e-be17-4b99-9920-b50604647396";
  espFsUuid = "BB64-E186";
  luksPartUuid = "40e7eb2f-14ed-4a85-9641-2eb0e6f2de2b"; # or null
  luksMapperName = "root";

  subvol = {
    root = "@";
    home = "@home";
    log = "@log";
    cache = null;
  };
};
```

For another machine, only swap values in this block (or run `scripts/bootstrap-variables.sh`) instead of editing module logic.

Optional cache subvolume mount:

```nix
storage = {
  # ...base values...
  subvol = {
    cache = "@cache";
  };
  cacheMountPoint = "/var/cache";
};
```

## Development shells

The flake includes two language shells:

- Rust shell:

```bash
nix develop .#rust
```

- Go shell:

```bash
nix develop .#go
```

Rust shell packages:

- `rustc`, `cargo`, `rustfmt`, `clippy`, `rust-analyzer`, `pkg-config`, `openssl`

Go shell packages:

- `go`, `gopls`, `delve`

## Editor and shell configs

- Zsh: `config/zsh/.zshrc`
- tmux: `config/tmux/tmux.conf`
- Neovim: `config/nvim/init.lua` and `config/nvim/lua/core/*`
- Doom Emacs: `config/doom/{init.el,config.el,packages.el}`

Bootstrap Doom once after first login:

```bash
${NIXOS_CONFIG_REPO:-/etc/nixos}/scripts/bootstrap-doom.sh
```

## Script style conventions

Shell scripts in `config/shell/bin` follow these conventions:

- Path variables use explicit suffixes: `*_DIR`, `*_FILE`, `*_PATH`
- Function names use lower snake case with action verbs
- Option/config variables are uppercase for quick scanning
- Command flow avoids deep nesting and keeps early exits explicit

## First login notes

- Default password is `changeme` in `hosts/artemis/variables.nix`
- Change it immediately:

```bash
passwd
```

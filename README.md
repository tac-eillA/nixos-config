<h1 align="center">
  <img src="./nixos-logo.png" width="110" />
  <br>
  Allison's NixOS Configuration
  <br>
  <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="620" />
</h1>

Flake-based NixOS config focused on:

- Niri + Waybar + Walker shell
- Dynamic wallpaper-driven theming
- Per-host `variables.nix` for machine/user settings
- Interactive live ISO installer
- Core developer tooling (`opencode`, Rust shell, Go shell)

## Installation

### Live ISO (recommended)

```bash
git clone <your-repo-url> ~/nixos-config
cd ~/nixos-config
sudo ./scripts/live-install.sh artemis
```

### Existing NixOS system

```bash
cd ~/nixos-config
./scripts/bootstrap-variables.sh artemis
sudo nixos-rebuild switch --flake .#artemis
```

## Docs

- `docs/INSTALLATION.md` - install paths, first boot, validation
- `docs/LIVE-INSTALLER.md` - full installer flow and partition behavior
- `docs/VARIABLES.md` - host variables model and examples
- `docs/STORAGE.md` - boot/disk model, subvolumes, LUKS behavior
- `docs/SHELL-AND-THEME.md` - shell scripts, keybinds, dynamic theme system
- `docs/DEVELOPMENT.md` - rebuild workflow, dev shells, opencode, git setup
- `docs/REPO-MAP.md` - where to edit each part of the repo

## Quick Notes

- Repo can live outside `/etc/nixos` (for example `~/nixos-config`).
- Set `paths.repoRoot` in `hosts/<host>/variables.nix`.
- Wallpapers belong in `config/wallpapers` (repo-managed) for automatic detection.
- `opencode` is installed as part of `modules/packages-core.nix`.

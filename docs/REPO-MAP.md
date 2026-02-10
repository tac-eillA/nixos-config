# Repo Map

## Top-Level

- `flake.nix` - flake inputs, host wiring, dev shells
- `hosts/` - host-specific config and variables
- `modules/` - reusable NixOS modules
- `config/` - repo-managed user config files (symlinked into `~/.config`)
- `scripts/` - bootstrap, installer, and helper scripts
- `docs/` - detailed documentation

## Hosts

- `hosts/<host>/configuration.nix` - module imports + host assembly
- `hosts/<host>/variables.nix` - user/machine-specific values
- `hosts/<host>/hardware-configuration.nix` - generated hardware declarations

## Modules

- `base.nix` - locale/timezone/shell defaults
- `boot-storage.nix` - generic storage/boot mounting and LUKS logic
- `services-core.nix` - core services
- `packages-core.nix` - core packages/fonts
- `desktop-niri.nix` - niri desktop wiring
- `shell-suite.nix` - shell utility services and timers
- profile modules - framework/nvidia/gaming toggles

## Shell Script Layer

Located at `config/shell/bin`.

These scripts control launcher/menu, screenshot, recording, update checks, wallpaper, and runtime theming.

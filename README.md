# nixos-config

Personal NixOS configuration for workstations, servers, and development shells.

This repo uses flakes and keeps host-specific configs under `hosts/` and shared modules under `modules/`.

Common commands:

- Rebuild the current machine: `sudo nixos-rebuild switch --flake .#$(hostname)`
- Show available flake outputs: `nix flake show`

Some hosts in `hosts/` are placeholders for future setup and need real `hardware-configuration.nix` files before deployment.

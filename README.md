# nixos-config

Personal NixOS configuration for workstations, servers, and development shells.

This repo uses flakes and keeps host-specific configs under `hosts/` and shared modules under `modules/`.

Some hosts in `hosts/` are placeholders for future setup and need real `hardware-configuration.nix` files before deployment.

## Install an existing NixOS system

After installing NixOS and cloning this repository, run:

```console
./scripts/install.sh
```

Choose **Default** to create a share-safe base host with no SOPS secrets, or
**Other** to deploy one of the existing host configurations. The installer
generates hardware configuration for new hosts, installs the bootloader, and
builds the selected configuration for the next boot. It never reboots the
machine automatically.

New hosts are discovered automatically from `hosts/<hostname>/configuration.nix`.
Commit the generated host directory if you want to keep it in the repository.

# Scylla

Reusable NixOS configuration for workstations, servers, and development shells.

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

## Users

Scylla keeps the primary account behind a small set of NixOS options instead
of embedding a personal username or home directory throughout the modules.
The repository defaults live in `modules/core/user.nix`. During a Default
installation, the installer opens that file in Nano so another user can update
the account and Git identity before rebuilding.

For a host maintained manually:

```nix
scylla.user = {
  name = "my-user";
  fullName = "My Name";
  # homeDirectory = "/custom/home"; # null defaults to /home/<name>
  git.name = "My Git Name";
  git.email = "me@example.com";
};
```

For multiple human accounts, keep `scylla.user` as the primary
Home Manager-managed desktop user and define additional accounts in a
host-specific module with `users.users.<name>`. If several users need fully
managed home environments, the next step is to turn `scylla.user` into an
attribute set of user profiles and create one `home-manager.users` entry per
enabled profile.

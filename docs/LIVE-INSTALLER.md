# Live Installer (`scripts/live-install.sh`)

This script provides an interactive install flow from the NixOS live environment.

## What It Does

- verifies live ISO + UEFI + root shell
- asks for username/fullname/password
- validates key prompt inputs (for example username pattern and absolute repo path)
- asks for profile toggles (`framework13`, `nvidiaDesktop`, `gaming`)
- supports partitioning modes:
  - automatic (wipe + create EFI/swap/root)
  - manual (runs `cfdisk`, then prompts for selected partitions)
- optional root LUKS encryption
- formats Btrfs root and creates subvolumes:
  - `@`, `@home`, `@log`, optional `@cache`
- mounts target filesystem tree under `/mnt`
- copies repo to `/mnt/etc/nixos`
- generates host hardware config
- writes host `variables.nix`
- optionally lets you edit variables before install
- shows a final install summary and asks for confirmation before formatting
- validates flake host output exists before `nixos-install`
- runs `nixos-install --flake /mnt/etc/nixos#<host>`
- sets installed user password via `nixos-enter`
- optionally copies repo to chosen runtime path (for example `~/nixos-config`)

## Usage

```bash
sudo ./scripts/live-install.sh artemis
```

## Important Notes

- Auto partition mode is destructive.
- Installer currently assumes Btrfs for root layout.
- Host directory must exist in repo (`hosts/<host>`).
- Flake output must exist for selected host (`nixosConfigurations.<host>`).
- Installer writes `paths.repoRoot` in host variables from your prompt input.

## Recovery / Retry

If install fails mid-way, rerun from live ISO. The script includes cleanup trap logic for mounts and LUKS mapping.

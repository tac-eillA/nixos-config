# Installation Guide

## Recommended Path: Live ISO

1. Boot NixOS live ISO in UEFI mode.
2. Clone your repo and enter it:

```bash
git clone <your-repo-url> ~/nixos-config
cd ~/nixos-config
```

3. Run the installer:

```bash
sudo ./scripts/live-install.sh artemis
```

4. Follow prompts in this order:
   - identity (`username`, `full name`, password)
   - target disk + partition mode (automatic or manual)
   - storage toggles (LUKS, cache subvolume)
   - final install plan summary (last confirmation before formatting)

## Prompt Guide (Live Installer)

- `Host name`: should match an existing flake host output (this repo defines `artemis`).
- `Repo root path on installed system`: use an absolute path, usually `/home/<user>/nixos-config`.
- `Partitioning mode`:
  - automatic: wipes selected disk and creates EFI/swap/root
  - manual: opens `cfdisk`, then you select existing EFI/root/swap partitions
- Manual partition prompts accept either partition names (`nvme0n1p2`) or full device paths (`/dev/nvme0n1p2`).

## Existing NixOS Path (No Reinstall)

If you are already on NixOS and only want to apply this config:

```bash
cd ~/nixos-config
./scripts/bootstrap-variables.sh artemis
sudo nixos-rebuild build --flake .#artemis
sudo nixos-rebuild switch --flake .#artemis
```

`bootstrap-variables.sh` now shows a full summary and asks for confirmation before writing `hosts/<host>/variables.nix`.

## First Boot Checklist

1. Sign in and verify Wayland + shell session starts cleanly.
2. Confirm your runtime repo path exists and is user-owned.
3. Run a rebuild from runtime repo:

```bash
sudo nixos-rebuild switch --flake /home/<user>/nixos-config#artemis
```

4. Test key shell actions:
   - `Mod+Space` (shell menu)
   - `Create Snapshot` and `Restore Snapshot`
   - `Fingerprint Setup` (if hardware is present)
   - `Mod+Return` / `Mod+Shift+Return` terminal behavior

## Validation Command

Run before major edits:

```bash
sudo nixos-rebuild build --flake .#artemis
```

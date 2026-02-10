# Storage and Boot Model

Boot and disk logic is generic in `modules/boot-storage.nix`.

Values come from `vars.storage` in your host variables file.

## Expected Layout

- UEFI boot (`/boot` on vfat)
- Btrfs root filesystem
- Subvolumes:
  - `@` -> `/`
  - `@home` -> `/home`
  - `@log` -> `/var/log`
  - optional cache subvol -> `/var/cache` (or custom mountpoint)
- Optional root LUKS unlock by `PARTUUID`

## Key Inputs

- `rootFsUuid`
- `espFsUuid`
- `luksPartUuid` (nullable)
- `luksMapperName`
- `subvol.root`, `subvol.home`, `subvol.log`, `subvol.cache`
- `cacheMountPoint`
- `btrfsMountOptions`
- `espMountOptions`

## Where to Edit

Edit host values in:

- `hosts/<host>/variables.nix`

Do not edit storage module logic unless you are changing architecture of the layout itself.

## Encryption Notes

- If `luksPartUuid = null`, initrd LUKS mapping is disabled.
- If set, initrd config maps to `luksMapperName` and enables discards.

{ lib, vars, ... }:
let
  storage = vars.storage;

  btrfsMountOptions =
    storage.btrfsMountOptions
    or [
      "compress=zstd:3"
      "ssd"
      "space_cache=v2"
    ];

  espMountOptions =
    storage.espMountOptions
    or [
      "fmask=0022"
      "dmask=0022"
      "utf8"
    ];

  luksPartUuid = storage.luksPartUuid or null;
  luksMapperName = storage.luksMapperName or "root";

  rootSubvol = storage.subvol.root or "@";
  homeSubvol = storage.subvol.home or "@home";
  logSubvol = storage.subvol.log or "@log";
  cacheSubvol = storage.subvol.cache or null;
  cacheMountPoint = storage.cacheMountPoint or "/var/cache";

  mkBtrfsMount = subvolName: {
    device = "/dev/disk/by-uuid/${storage.rootFsUuid}";
    fsType = "btrfs";
    options = [ "subvol=${subvolName}" ] ++ btrfsMountOptions;
  };
in
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices = lib.mkIf (luksPartUuid != null) {
    "${luksMapperName}" = {
      device = "/dev/disk/by-partuuid/${luksPartUuid}";
      allowDiscards = true;
    };
  };

  fileSystems =
    {
      "/" = mkBtrfsMount rootSubvol;
      "/home" = mkBtrfsMount homeSubvol;
      "/var/log" = mkBtrfsMount logSubvol;

      "/boot" = {
        device = "/dev/disk/by-uuid/${storage.espFsUuid}";
        fsType = "vfat";
        options = espMountOptions;
      };
    }
    // lib.optionalAttrs (cacheSubvol != null) {
      "${cacheMountPoint}" = mkBtrfsMount cacheSubvol;
    };

  boot.kernelParams = [
    "quiet"
    "zswap.enabled=0"
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 12;
  };
}

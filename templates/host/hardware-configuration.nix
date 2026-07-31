{ lib, ... }:

{
  # This lets the template evaluate, but it must be replaced by the installer
  # with the output of nixos-generate-config before deploying a real machine.
  fileSystems."/" = {
    device = lib.mkDefault "/dev/disk/by-label/replace-me-root";
    fsType = lib.mkDefault "ext4";
  };

  fileSystems."/boot" = {
    device = lib.mkDefault "/dev/disk/by-label/replace-me-boot";
    fsType = lib.mkDefault "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

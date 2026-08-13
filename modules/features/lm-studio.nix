{ config, pkgs, ... }:

{
  hardware.amdgpu.opencl.enable = true;

  users.users.${config.scylla.user.name}.extraGroups = [
    "render"
    "video"
  ];

  environment.systemPackages = with pkgs; [
    clinfo
    libva-utils
    (callPackage ../packages/lmstudio.nix { })
    rocmPackages.amdsmi
    rocmPackages.rocminfo
  ];
}

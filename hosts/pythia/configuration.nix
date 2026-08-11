{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ../../modules/profiles/workstation.nix
    ../../modules/features/lm-studio.nix
    ../../modules/features/remote-development.nix
  ];

  networking.hostName = "pythia";

  hardware.enableRedistributableFirmware = true;

  # This limit gives the 128 GB model 100 GB of shared GPU memory.
  boot.extraModprobeConfig = ''
    options ttm pages_limit=26214400
  '';

  scylla.desktop.video.gpu = "amd";
}

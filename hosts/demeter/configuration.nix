{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
  ];

  networking.hostName = "demeter";

  scylla.desktop.video.gpu = "nvidia";
}

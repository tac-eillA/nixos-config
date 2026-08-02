{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  scylla.desktop.video.gpu = "nvidia";
}

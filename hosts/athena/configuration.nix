{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "athena";

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.power-profiles-daemon.enable = true;
}

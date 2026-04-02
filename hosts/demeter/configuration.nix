{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "demeter";

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
}

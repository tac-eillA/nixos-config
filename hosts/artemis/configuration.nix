{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "artemis";

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
}

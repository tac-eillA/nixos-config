# modules/plasma.nix
{ config, pkgs, ... }:

{
  services.xserver.enable = true;

  services.displayManager.plasma-login-manager.enable = true;

  services.desktopManager.plasma6.enable = true;

  # Keep Plasma/Qt apps behaving nicely with file pickers and open handlers
  xdg.portal.enable = true;
  xdg.portal.xdgOpenUsePortal = true;

  # Good QoL on laptops; harmless on desktops if you want it everywhere
  services.power-profiles-daemon.enable = true;

  # Nice if you use headphones/controllers/etc.
  hardware.bluetooth.enable = true;

  # Phone integration
  programs.kdeconnect.enable = true;

  # Optional: trim Plasma a bit
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    plasma-browser-integration
  ];

  environment.systemPackages = with pkgs; [
    kdePackages.kate
    kdePackages.filelight
    kdePackages.partitionmanager
  ];
}

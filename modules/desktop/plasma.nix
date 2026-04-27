{ pkgs, ... }:

{
  services.xserver.enable = true;
  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager.plasma6.enable = true;

  xdg.portal.enable = true;
  xdg.portal.xdgOpenUsePortal = true;

  services.power-profiles-daemon.enable = true;

  programs.kdeconnect.enable = true;

  # Trim a few bundled Plasma apps.
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

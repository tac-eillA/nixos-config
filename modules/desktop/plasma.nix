{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.allison.desktop.sessions.plasma.enable {
    services.desktopManager.plasma6.enable = true;

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
  };
}

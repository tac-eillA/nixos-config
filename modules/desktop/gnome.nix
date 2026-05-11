{ config, lib, pkgs, ... }:

let
  cfg = config.allison.desktop.sessions.gnome;
in
{
  config = lib.mkIf cfg.enable {
    services.desktopManager.gnome.enable = true;

    environment.gnome.excludePackages = with pkgs; [
      epiphany
      geary
      gnome-connections
      gnome-music
      gnome-tour
      totem
    ];
  };
}

{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.allison.desktop.sessions.hyprland.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    programs.uwsm.enable = true;

    # Needed by GTK applications, screen sharing, and desktop file launchers.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.hyprland.default = [
        "hyprland"
        "gtk"
      ];
    };

    security.pam.services.hyprlock = { };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };
  };
}

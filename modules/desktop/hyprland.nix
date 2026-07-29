{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.scylla.desktop.sessions.hyprland.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    programs.uwsm.enable = true;

    programs.thunar = {
      enable = true;
      plugins = [ pkgs.thunar-archive-plugin ];
    };

    services.gvfs = {
      enable = true;
      # The default NixOS package enables online-account integration. Thunar
      # only needs the desktop-neutral local/removable/network backends.
      package = pkgs.gvfs;
    };
    services.tumbler.enable = true;

    # Needed by GTK applications, screen sharing, and desktop file launchers.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.hyprland.default = [
        "hyprland"
        "gtk"
      ];
      config.hyprland."org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };

    security.pam.services.hyprlock.fprintAuth = true;

    environment.systemPackages = with pkgs; [
      imv
      xarchiver
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };
  };
}

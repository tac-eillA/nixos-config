{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.scylla.desktop.sessions.gnome.enable {
    services.desktopManager.gnome.enable = true;

    programs.thunar = {
      enable = true;
      plugins = [ pkgs.thunar-archive-plugin ];
    };

    services.gvfs = {
      enable = true;
      package = pkgs.gvfs;
    };
    services.tumbler.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
      config.gnome.default = [ "gnome" "gtk" ];
      config.gnome."org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };

    environment.systemPackages = with pkgs; [
      gnome-screenshot
      gnomeExtensions.appindicator
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.extension-list
      gnomeExtensions.tiling-assistant
      imv
      xarchiver
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };
  };
}

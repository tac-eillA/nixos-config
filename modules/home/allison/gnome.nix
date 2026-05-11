{ pkgs, ... }:

let
  wallpaper = ../../../img/wallpaper/oilPainting.jpg;
  wallpaperUri = "file://${wallpaper}";
  extensions = with pkgs.gnomeExtensions; [
    appindicator
    caffeine
    gsconnect
    tiling-assistant
  ];
in
{
  home.packages = with pkgs; [
    adwaita-icon-theme
    adwaita-icon-theme-legacy
    bibata-cursors
    gnome-extension-manager
    gnome-tweaks
  ] ++ extensions;

  dconf = {
    enable = true;

    settings = {
      "org/gnome/desktop/background" = {
        picture-uri = wallpaperUri;
        picture-uri-dark = wallpaperUri;
        picture-options = "zoom";
      };

      "org/gnome/desktop/screensaver" = {
        picture-uri = wallpaperUri;
        picture-options = "zoom";
      };

      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        clock-show-weekday = true;
        enable-hot-corners = false;
        gtk-theme = "Adwaita";
        icon-theme = "Adwaita";
        cursor-theme = "Bibata-Modern-Classic";
      };

      "org/gnome/shell" = {
        enabled-extensions = map (extension: extension.extensionUuid) extensions;
      };

      "org/gnome/mutter" = {
        dynamic-workspaces = false;
      };

      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 4;
      };

      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
        maximize = [ "<Super>Up" ];
        minimize = [ "<Super>Down" ];

        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        switch-to-workspace-4 = [ "<Super>4" ];
        switch-to-workspace-5 = [ "<Super>5" ];

        move-to-workspace-1 = [ "<Super><Shift>1" ];
        move-to-workspace-2 = [ "<Super><Shift>2" ];
        move-to-workspace-3 = [ "<Super><Shift>3" ];
        move-to-workspace-4 = [ "<Super><Shift>4" ];
        move-to-workspace-5 = [ "<Super><Shift>5" ];
      };

      "org/gnome/mutter/keybindings" = {
        toggle-tiled-left = [ "<Super><Shift>h" ];
        toggle-tiled-right = [ "<Super><Shift>l" ];
      };

      "org/gnome/shell/keybindings" = {
        switch-to-application-1 = [ ];
        switch-to-application-2 = [ ];
        switch-to-application-3 = [ ];
        switch-to-application-4 = [ ];
        switch-to-application-5 = [ ];
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Launch Ghostty";
        command = "ghostty";
        binding = "<Super>Return";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Launch Firefox";
        command = "firefox";
        binding = "<Super>b";
      };
    };
  };
}

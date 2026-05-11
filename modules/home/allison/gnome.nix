{ lib, pkgs, ... }:

let
  wallpaper = ../../../img/wallpaper/oilPainting.jpg;
  wallpaperUri = "file://${wallpaper}";
  numbers = lib.range 1 10;
  emptyKeybindings = prefixes:
    lib.genAttrs
      (lib.concatMap
        (prefix: map (number: "${prefix}-${toString number}") numbers)
        prefixes)
      (_: [ ]);
  extensions = with pkgs.gnomeExtensions; [
    appindicator
    caffeine
    clipboard-history
    dash-to-dock
    just-perfection
    space-bar
    vitals
  ];
in
{
  home.packages =
    with pkgs;
    [
      adwaita-icon-theme
      adwaita-icon-theme-legacy
      bibata-cursors
      gnome-extension-manager
      gnome-tweaks
    ]
    ++ extensions;

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
        favorite-apps = [
          "firefox.desktop"
          "com.mitchellh.ghostty.desktop"
          "dev.zed.Zed.desktop"
          "org.gnome.Nautilus.desktop"
        ];
      };

      "org/gnome/shell/extensions/dash-to-dock" = {
        hot-keys = false;
        hotkeys-overlay = false;
        hotkeys-show-dock = false;
        shortcut = [ ];
        shortcut-text = "";
        show-trash = true;
        show-mounts = false;
        show-show-apps-button = true;
        show-apps-at-top = false;
      } // emptyKeybindings [
        "app-hotkey"
        "app-shift-hotkey"
        "app-ctrl-hotkey"
      ];

      "org/gnome/shell/extensions/space-bar/shortcuts" = {
        enable-activate-workspace-shortcuts = false;
        enable-move-to-workspace-shortcuts = false;
        move-workspace-left = [ ];
        move-workspace-right = [ ];
        activate-previous-key = [ ];
        activate-empty-key = [ ];
        open-menu = [ ];
      } // emptyKeybindings [ "activate" ];

      "org/gnome/mutter" = {
        dynamic-workspaces = false;
      };

      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 5;
      };

      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
        maximize = [ "<Super>Up" ];
        minimize = [ "<Super>Down" ];
        unmaximize = [ ];

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

      "org/gnome/shell/keybindings" =
        emptyKeybindings [ "switch-to-application" ];

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

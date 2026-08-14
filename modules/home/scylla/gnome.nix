{ lib, pkgs, ... }:

let
  wallpaper = ../../../img/wallpaper/oilPainting.jpg;
  customKeybinding = name: binding: command: {
    name = "Scylla ${name}";
    inherit binding command;
  };
  customKeybindingPath = name:
    "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/scylla-${name}/";
  wallpaperSwitcher = pkgs.writeShellApplication {
    name = "scylla-theme";
    runtimeInputs = with pkgs; [ coreutils glib libnotify ];
    text = ''
      if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
        echo "usage: scylla-theme WALLPAPER" >&2
        exit 2
      fi

      selected="$(realpath "$1")"
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/scylla-theme"
      mkdir -p "$state_dir"
      ln -sfn "$selected" "$state_dir/wallpaper"
      gsettings set org.gnome.desktop.background picture-uri "file://$selected"
      gsettings set org.gnome.desktop.background picture-uri-dark "file://$selected"
      gsettings set org.gnome.desktop.interface color-scheme prefer-dark
      gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
      notify-send "Wallpaper updated" "$(basename "$selected")"
    '';
  };
in
{
  home.packages = with pkgs; [
    brightnessctl
    libnotify
    networkmanager
    networkmanagerapplet
    pavucontrol
    wallpaperSwitcher
    ddcutil
  ];

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  programs.vicinae = {
    enable = true;
    systemd.enable = true;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
    };

    "org/gnome/desktop/background" = {
      picture-uri = "file://${wallpaper}";
      picture-uri-dark = "file://${wallpaper}";
      picture-options = "zoom";
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
    };

    "org/gnome/shell" = {
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "clipboard-indicator@tudmotu.com"
        "tiling-assistant@leleat-on-github"
      ];
    };

    # GNOME normally uses Super+1 through Super+9 to launch favorite apps.
    # Release Super+1 through Super+5 for workspace navigation.
    "org/gnome/shell/keybindings" = {
      switch-to-application-1 = [ ];
      switch-to-application-2 = [ ];
      switch-to-application-3 = [ ];
      switch-to-application-4 = [ ];
      switch-to-application-5 = [ ];
    };

    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 5;
      focus-mode = "sloppy";
    };

    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
      toggle-fullscreen = [ "<Super>f" ];
      focus-left = [ "<Super>h" ];
      focus-down = [ "<Super>j" ];
      focus-up = [ "<Super>k" ];
      focus-right = [ "<Super>l" ];
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

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = map customKeybindingPath [
        "terminal"
        "browser"
        "browser2"
        "t3code"
        "files"
        "vicinae"
        "display-settings"
        "wallpaper-settings"
        "lock"
        "diagnostics"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/scylla-terminal" =
      customKeybinding "Terminal" "<Super>Return" "ghostty";
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/scylla-browser" =
      customKeybinding "Firefox" "<Super>b" "firefox";
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/scylla-browser2" =
      customKeybinding "Helium" "<Super><Shift>b" "helium";
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/scylla-t3code" =
      customKeybinding "T3 Code" "<Super><Shift>c" "t3code";
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/scylla-files" =
      customKeybinding "Files" "<Super>e" "thunar";
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/scylla-vicinae" =
      customKeybinding "Vicinae" "<Super>space" "vicinae toggle";
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/scylla-display-settings" =
      customKeybinding "Display settings" "<Super><Shift>m" "gnome-control-center display";
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/scylla-wallpaper-settings" =
      customKeybinding "Wallpaper settings" "<Super><Shift>w" "gnome-control-center background";
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/scylla-lock" =
      customKeybinding "Lock session" "<Super>escape" "loginctl lock-session";
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/scylla-diagnostics" =
      customKeybinding "Diagnostics" "<Super>d" "gnome-system-monitor";
  };

  home.activation.seedDesktopTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/scylla-theme"
    if [ ! -e "$state_dir/wallpaper" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$state_dir"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -s "${wallpaper}" "$state_dir/wallpaper"
    fi
  '';
}

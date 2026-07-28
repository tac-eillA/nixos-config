{ pkgs, ... }:

let
  wallpaper = ../../../img/wallpaper/oilPainting.jpg;
  quickshellConfig = builtins.replaceStrings
    [ "@WALLPAPER@" ]
    [ "${wallpaper}" ]
    (builtins.readFile ./hyprland/quickshell/shell.qml);
in
{
  home.packages = with pkgs; [
    bibata-cursors
    brightnessctl
    grimblast
    hypridle
    hyprlock
    libnotify
    networkmanager
    quickshell
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
      name = "Adwaita";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  programs.vicinae = {
    enable = true;
    systemd.enable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    configType = "lua";

    # Keep the compositor configuration in Home Manager, but use native Lua.
    # The structured settings generator is intentionally not used here because
    # Hyprland's Lua API is typed and differs substantially from hyprlang.
    settings = { };
    extraConfig = builtins.readFile ./hyprland/hyprland.lua;
  };

  # UWSM owns the session environment, including cursor variables.
  xdg.configFile."uwsm/env".text = ''
    export XCURSOR_SIZE=24
    export HYPRCURSOR_SIZE=24
  '';

  xdg.configFile."quickshell/allison/shell.qml".text = quickshellConfig;

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general.hide_cursor = true;
      background = [{
        path = "${wallpaper}";
        blur_passes = 3;
        blur_size = 8;
      }];
      input-field = [{
        size = "300, 50";
        position = "0, -40";
        monitor = "";
        dots_center = true;
        fade_on_empty = false;
        placeholder_text = "Password";
        outline_thickness = 2;
      }];
      label = [{
        monitor = "";
        text = "$TIME";
        font_size = 72;
        position = "0, 100";
        valign = "center";
        halign = "center";
      }];
    };
  };
}

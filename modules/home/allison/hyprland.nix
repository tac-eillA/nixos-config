{ lib, pkgs, ... }:

let
  wallpaper = ../../../img/wallpaper/oilPainting.jpg;
  defaultMonitorConfig = pkgs.writeText "hyprland-default-monitors.lua" ''
    -- This file is copied to ~/.config/hypr/monitors.lua only when it does
    -- not already exist. Display changes saved by wdisplays remain mutable.
    hl.monitor({
      output = "",
      mode = "preferred",
      position = "auto",
      scale = 1,
    })
  '';
  persistentWdisplays = pkgs.writeShellApplication {
    name = "wdisplays";
    runtimeInputs = with pkgs; [
      coreutils
      hyprland
      jq
      wdisplays
    ];
    text = ''
      status=0
      ${pkgs.wdisplays}/bin/wdisplays || status=$?

      # Hyprland may disconnect wdisplays after accepting its output-management
      # request, which makes GTK exit non-zero even though the layout changed.
      # Treat the compositor's resulting state as authoritative instead.
      config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
      monitor_config="$config_home/hypr/monitors.lua"
      monitor_tmp="$monitor_config.tmp"

      mkdir -p "$config_home/hypr"
      if ${pkgs.hyprland}/bin/hyprctl monitors all -j | ${pkgs.jq}/bin/jq -r '
        .[] |
        if .disabled then
          "hl.monitor({ output = \(.name | @json), disabled = true })"
        else
          "hl.monitor({ output = \(.name | @json), mode = \(("\(.width)x\(.height)@\(.refreshRate)") | @json), position = \(("\(.x)x\(.y)") | @json), scale = \(.scale), transform = \(.transform) })"
        end
      ' > "$monitor_tmp" && [ -s "$monitor_tmp" ]; then
        mv "$monitor_tmp" "$monitor_config"
        ${pkgs.hyprland}/bin/hyprctl reload
      else
        rm -f "$monitor_tmp"
      fi

      exit "$status"
    '';
  };
  quickshellConfig = pkgs.writeText "allison-quickshell.qml" (
    builtins.replaceStrings
      [ "@WALLPAPER@" ]
      [ "${wallpaper}" ]
      (builtins.readFile ./hyprland/quickshell/shell.qml)
  );
in
{
  home.packages = with pkgs; [
    bibata-cursors
    brightnessctl
    grimblast
    hypridle
    hyprlock
    hyprpolkitagent
    libnotify
    blueman
    networkmanager
    networkmanagerapplet
    pavucontrol
    quickshell
    persistentWdisplays
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
      package = pkgs.gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "image/bmp" = [ "imv.desktop" ];
      "image/gif" = [ "imv.desktop" ];
      "image/jpeg" = [ "imv.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "image/webp" = [ "imv.desktop" ];
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

  # UWSM owns the Hyprland session environment. Use the toolkits' built-in
  # input contexts so no separate input-method daemon is started.
  xdg.configFile."uwsm/env".text = ''
    export XCURSOR_SIZE=24
    export HYPRCURSOR_SIZE=24
    export GTK_IM_MODULE=gtk-im-context-simple
    export QT_IM_MODULE=
    export XMODIFIERS=
  '';

  xdg.configFile."quickshell/allison/shell.qml".source = quickshellConfig;

  systemd.user.services.quickshell-allison = {
    Unit = {
      Description = "Allison Quickshell desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      X-Restart-Triggers = [ quickshellConfig ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs -c allison";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland polkit authentication agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe pkgs.hyprpolkitagent;
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Monitor layouts are intentionally mutable. Home Manager seeds this file
  # once, then the wdisplays wrapper updates it after a successful GUI session.
  home.activation.seedHyprlandMonitorConfig =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
      monitor_config="$config_home/hypr/monitors.lua"

      if [ ! -e "$monitor_config" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 \
          ${defaultMonitorConfig} "$monitor_config"
        if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          $DRY_RUN_CMD ${pkgs.hyprland}/bin/hyprctl reload >/dev/null 2>&1 || true
        fi
      fi
    '';

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

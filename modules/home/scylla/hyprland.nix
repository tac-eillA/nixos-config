{ lib, osConfig, pkgs, ... }:

let
  wallpaper = ../../../img/wallpaper/oilPainting.jpg;
  repositoryWallpapers = ../../../img/wallpaper;
  shellCfg = osConfig.scylla.desktop.shell;
  shellRuntimeSettings = {
    repositoryWallpapers = toString repositoryWallpapers;
    inherit (shellCfg) displayProfiles internalDisplay tabletModePath;
    adaptive = shellCfg.adaptive;
  };
  shellRuntimeJson = pkgs.writeText "scylla-shell.json"
    (builtins.toJSON shellRuntimeSettings);
  shellRuntimeQml = pkgs.writeText "RuntimeConfig.qml" ''
    import QtQuick

    QtObject {
      readonly property var settings: (${builtins.toJSON shellRuntimeSettings})
    }
  '';
  nvidiaRuntimeInputs = lib.optional
    (osConfig.scylla.desktop.video.gpu == "nvidia")
    osConfig.boot.kernelPackages.nvidiaPackages.latest;
  themeTemplate = ./hyprland/theme.json.tpl;
  themeConfig = pkgs.writeText "scylla-matugen.toml" (
    builtins.replaceStrings
      [ "@THEME_TEMPLATE@" ]
      [ "${themeTemplate}" ]
      (builtins.readFile ./hyprland/matugen.toml)
  );
  themeSwitcher = pkgs.writeShellApplication {
    name = "scylla-theme";
    runtimeInputs = with pkgs; [
      coreutils
      glib
      hyprland
      jq
      libnotify
      matugen
    ];
    text = ''
      usage() {
        echo "usage: scylla-theme WALLPAPER" >&2
      }

      case "''${1:-}" in
        -h|--help)
          usage
          exit 0
          ;;
      esac

      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/scylla-theme"
      mkdir -p "$state_dir"

      if [ "$#" -ne 1 ]; then
        usage
        exit 2
      fi
      selected="$1"

      if [ -z "''${selected:-}" ] || [ ! -f "$selected" ]; then
        echo "Wallpaper not found: ''${selected:-<none>}" >&2
        exit 1
      fi

      selected="$(realpath "$selected")"
      ln -sfn "$selected" "$state_dir/wallpaper"

      # Keep the desktop OLED-friendly while deriving its accents and surfaces
      # from the selected image.
      matugen image "$selected" \
        --config ${themeConfig} \
        --mode dark \
        --source-color-index 0 \
        --quiet

      accent="$(jq -r '.accent | ltrimstr("#")' "$state_dir/theme.json")"
      outline="$(jq -r '.outline | ltrimstr("#")' "$state_dir/theme.json")"

      gsettings set org.gnome.desktop.interface color-scheme prefer-dark
      gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark

      if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl keyword general:col.active_border "rgba(''${accent}ee)"
        hyprctl keyword general:col.inactive_border "rgba(''${outline}aa)"
      fi

      notify-send "Theme updated" "$(basename "$selected")"
    '';
  };
  todoManager = pkgs.writeShellApplication {
    name = "scylla-todo";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = ''
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/scylla-shell"
      todo_file="$state_dir/todos.json"
      mkdir -p "$state_dir"
      if [ ! -e "$todo_file" ]; then
        printf '[]\n' > "$todo_file"
      fi

      command="''${1:-list}"
      case "$command" in
        list)
          jq '.' "$todo_file"
          ;;
        add)
          [ "$#" -eq 2 ] && [ -n "$2" ] || {
            echo "usage: scylla-todo add TEXT" >&2
            exit 2
          }
          task_id="$(date +%s%N)"
          tmp_file="$todo_file.tmp"
          jq --arg taskId "$task_id" --arg text "$2" \
            '. + [{ taskId: $taskId, text: $text, done: false }]' \
            "$todo_file" > "$tmp_file"
          mv "$tmp_file" "$todo_file"
          ;;
        toggle)
          [ "$#" -eq 2 ] || exit 2
          tmp_file="$todo_file.tmp"
          jq --arg taskId "$2" \
            'map(if .taskId == $taskId then .done = (.done | not) else . end)' \
            "$todo_file" > "$tmp_file"
          mv "$tmp_file" "$todo_file"
          ;;
        remove)
          [ "$#" -eq 2 ] || exit 2
          tmp_file="$todo_file.tmp"
          jq --arg taskId "$2" \
            'map(select(.taskId != $taskId))' \
            "$todo_file" > "$tmp_file"
          mv "$tmp_file" "$todo_file"
          ;;
        *)
          echo "usage: scylla-todo {list|add|toggle|remove}" >&2
          exit 2
          ;;
      esac
    '';
  };
  displayController = pkgs.writeShellApplication {
    name = "scylla-displayctl";
    runtimeInputs = with pkgs; [
      coreutils
      ddcutil
      gawk
      hyprland
      jq
      brightnessctl
      systemd
    ];
    text = builtins.readFile ./hyprland/scripts/scylla-displayctl;
  };
  resourceUsageCollector = pkgs.writeShellApplication {
    name = "scylla-resource-usage";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      jq
      procps
    ] ++ nvidiaRuntimeInputs;
    text = builtins.readFile ./hyprland/scripts/scylla-resource-usage;
  };
  diagnosticsCollector = pkgs.writeShellApplication {
    name = "scylla-diagnostics";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      hyprland
      jq
      systemd
    ];
    text = builtins.readFile ./hyprland/scripts/scylla-diagnostics;
  };
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
    text = ''
      status=0
      ${pkgs.wdisplays}/bin/wdisplays || status=$?

      # Hyprland may disconnect wdisplays after accepting its output-management
      # request, which makes GTK exit non-zero even though the layout changed.
      # Treat the compositor's resulting state as authoritative and serialize
      # it through the same backend used by native shell controls.
      ${displayController}/bin/scylla-displayctl persist-current || true

      exit "$status"
    '';
  };
  quickshellConfig = pkgs.runCommand "scylla-quickshell-config" { } ''
    mkdir -p "$out"
    cp -R ${./hyprland/quickshell}/. "$out/"
    chmod u+w "$out/RuntimeConfig.qml"
    cp ${shellRuntimeQml} "$out/RuntimeConfig.qml"
  '';
in
{
  home.packages = with pkgs; [
    brightnessctl
    grimblast
    hypridle
    hyprpolkitagent
    libnotify
    blueman
    networkmanager
    networkmanagerapplet
    pavucontrol
    quickshell
    resourceUsageCollector
    diagnosticsCollector
    displayController
    themeSwitcher
    todoManager
    persistentWdisplays
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

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Adwaita-dark";
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

  xdg.configFile."quickshell/scylla".source = quickshellConfig;
  xdg.configFile."scylla/shell.json".source = shellRuntimeJson;
  xdg.configFile."matugen/config.toml".source = themeConfig;
  xdg.configFile."matugen/theme.json.tpl".source = themeTemplate;

  # Runtime theme state is deliberately mutable. Seed it once; wallpaper
  # choices made by scylla-theme survive Home Manager rebuilds.
  home.activation.seedDesktopTheme =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/scylla-theme"
      if [ ! -e "$state_dir/wallpaper" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$state_dir"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -s "${wallpaper}" "$state_dir/wallpaper"
      fi
    '';

  systemd.user.services.quickshell-scylla = {
    Unit = {
      Description = "Scylla Quickshell desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      X-Restart-Triggers = [
        quickshellConfig
        shellRuntimeJson
      ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs -c scylla";
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
      # hyprpolkitagent is installed under libexec in 0.1.3 even though its
      # mainProgram metadata makes lib.getExe incorrectly point at bin/.
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
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

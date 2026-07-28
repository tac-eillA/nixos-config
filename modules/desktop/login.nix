{ config, lib, pkgs, ... }:

let
  cfg = config.allison.desktop;
  sddmTheme = pkgs.runCommand "allison-sddm-theme" { } ''
    mkdir -p "$out/share/sddm/themes/allison"
    cp ${./sddm-theme/Main.qml} "$out/share/sddm/themes/allison/Main.qml"
    cp ${./sddm-theme/metadata.desktop} "$out/share/sddm/themes/allison/metadata.desktop"
    touch "$out/share/sddm/themes/allison/theme.conf"
  '';
in
{
  options.allison.desktop = {
    defaultSession = lib.mkOption {
      type = lib.types.enum [ "hyprland-uwsm" ];
      default = "hyprland-uwsm";
      description = "Desktop session the login manager should start by default.";
    };

    sessions.hyprland.enable = lib.mkEnableOption "Hyprland desktop session" // {
      default = true;
    };

    login.internalDisplayOnly = lib.mkEnableOption "show the login screen only on the built-in laptop display";
  };

  config = {
    assertions = [
      {
        assertion = cfg.defaultSession != "hyprland-uwsm" || cfg.sessions.hyprland.enable;
        message = ''allison.desktop.defaultSession = "hyprland-uwsm" requires allison.desktop.sessions.hyprland.enable = true.'';
      }
    ];

    # SDDM owns only authentication and session launch. UWSM owns the
    # Hyprland session and its shutdown path.
    services.xserver.enable = true;

    services.displayManager = {
      defaultSession = cfg.defaultSession;
      sddm = {
        enable = true;
        theme = "${sddmTheme}/share/sddm/themes/allison";
        wayland.enable = false;
        settings = {
          Users = {
            RememberLastSession = true;
            RememberLastUser = true;
          };
          Theme = {
            CursorTheme = "Bibata-Modern-Classic";
            CursorSize = 24;
          };
        };
      };
    };

    services.xserver.displayManager.setupCommands =
      lib.optionalString cfg.login.internalDisplayOnly ''
        # Xorg uses names such as eDP, eDP-1, LVDS-1, or DSI-1 for built-in
        # panels. Discover it instead of coupling the greeter to a dock port.
        internal_output="$(${lib.getExe pkgs.xrandr} --query | ${lib.getExe pkgs.gawk} \
          '$2 == "connected" && $1 ~ /^(eDP|LVDS|DSI)/ { print $1; exit }')"

        if [ -n "$internal_output" ]; then
          ${lib.getExe pkgs.xrandr} --output "$internal_output" --auto --primary

          ${lib.getExe pkgs.xrandr} --query | ${lib.getExe pkgs.gawk} \
            -v internal="$internal_output" '$2 == "connected" && $1 != internal { print $1 }' |
            while IFS= read -r output; do
              ${lib.getExe pkgs.xrandr} --output "$output" --off
            done
        fi
      '';

    environment.systemPackages = [
      pkgs.bibata-cursors
      sddmTheme
    ];

    xdg.portal.enable = true;
    xdg.portal.xdgOpenUsePortal = true;

    services.power-profiles-daemon.enable = true;

    home-manager.users.allison.imports =
      lib.optionals cfg.sessions.hyprland.enable [ ../home/allison/hyprland.nix ];
  };
}

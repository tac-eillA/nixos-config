{ config, lib, pkgs, ... }:

let
  cfg = config.scylla.desktop;
  sddmTheme = pkgs.runCommand "scylla-sddm-theme" { } ''
    mkdir -p "$out/share/sddm/themes/scylla"
    cp ${./sddm-theme/Main.qml} "$out/share/sddm/themes/scylla/Main.qml"
    cp ${./sddm-theme/metadata.desktop} "$out/share/sddm/themes/scylla/metadata.desktop"
    touch "$out/share/sddm/themes/scylla/theme.conf"
  '';
in
{
  options.scylla.desktop = {
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
        message = ''scylla.desktop.defaultSession = "hyprland-uwsm" requires scylla.desktop.sessions.hyprland.enable = true.'';
      }
    ];

    # SDDM owns only authentication and session launch. UWSM owns the
    # Hyprland session and its shutdown path.
    services.xserver.enable = true;

    services.displayManager = {
      defaultSession = cfg.defaultSession;
      sddm = {
        enable = true;
        theme = "${sddmTheme}/share/sddm/themes/scylla";
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

    # Keep the login keyring available without pulling the GNOME desktop back
    # in. PAM unlocks it with the SDDM password, and NetworkManager can then
    # retrieve user-scoped Wi-Fi secrets after the session starts.
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.sddm = {
      # SDDM cannot race password and fingerprint authentication cleanly.
      # With fprintd enabled globally it waits for the fingerprint timeout
      # before accepting an already-entered password.
      fprintAuth = false;
      enableGnomeKeyring = true;
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

    home-manager.users.${config.scylla.user.name}.imports =
      lib.optionals cfg.sessions.hyprland.enable [ ../home/scylla/hyprland.nix ];
  };
}

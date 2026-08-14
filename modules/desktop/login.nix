{ config, lib, pkgs, ... }:

let
  cfg = config.scylla.desktop;
in
{
  options.scylla.desktop = {
    defaultSession = lib.mkOption {
      type = lib.types.enum [ "gnome" ];
      default = "gnome";
      description = "Desktop session the login manager should start by default.";
    };

    sessions.gnome.enable = lib.mkEnableOption "GNOME desktop session" // {
      default = true;
    };

  };

  config = {
    assertions = [
      {
        assertion = cfg.defaultSession != "gnome" || cfg.sessions.gnome.enable;
        message = ''scylla.desktop.defaultSession = "gnome" requires scylla.desktop.sessions.gnome.enable = true.'';
      }
    ];

    # GDM owns authentication and GNOME session launch.
    services.xserver.enable = true;

    services.displayManager.defaultSession = cfg.defaultSession;
    services.displayManager.gdm.enable = true;

    # Keep the login keyring available. PAM unlocks it with the GDM password, and NetworkManager can then
    # retrieve user-scoped Wi-Fi secrets after the session starts.
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.gdm = {
      fprintAuth = false;
      enableGnomeKeyring = true;

      rules.auth = {
        # Use password authentication for the greeter.
        login.enable = lib.mkForce false;

        unix = {
          order = 11000;
          control = lib.mkForce "required";
          modulePath = config.security.pam.pam_unixModulePath;
          settings = {
            likeauth = true;
            try_first_pass = true;
          };
        };

        gnome_keyring = {
          order = 12000;
          control = "optional";
          modulePath = "${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so";
        };
      };
    };

    environment.systemPackages = [
      pkgs.bibata-cursors
    ];

    xdg.portal.enable = true;
    xdg.portal.xdgOpenUsePortal = true;

    services.power-profiles-daemon.enable = true;

    home-manager.users.${config.scylla.user.name}.imports =
      lib.optionals cfg.sessions.gnome.enable [ ../home/scylla/gnome.nix ];
  };
}

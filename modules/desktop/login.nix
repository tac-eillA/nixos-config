{ config, lib, ... }:

let
  cfg = config.allison.desktop;
  wallpaper = ../../img/wallpaper/oilPainting.jpg;
  wallpaperPath = "${wallpaper}";
  wallpaperUri = "file://${wallpaperPath}";
in
{
  options.allison.desktop = {
    defaultSession = lib.mkOption {
      type = lib.types.enum [
        "gnome"
        "hyprland-uwsm"
      ];
      default = "gnome";
      description = "Desktop session GDM should select by default.";
    };

    sessions = {
      gnome.enable = lib.mkEnableOption "GNOME desktop session" // {
        default = true;
      };
      hyprland.enable = lib.mkEnableOption "Hyprland desktop session" // {
        default = true;
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.sessions.gnome.enable;
        message = "GNOME desktop session must be enabled.";
      }
      {
        assertion = cfg.defaultSession != "gnome" || cfg.sessions.gnome.enable;
        message = ''allison.desktop.defaultSession = "gnome" requires allison.desktop.sessions.gnome.enable = true.'';
      }
      {
        assertion = cfg.defaultSession != "hyprland-uwsm" || cfg.sessions.hyprland.enable;
        message = ''allison.desktop.defaultSession = "hyprland-uwsm" requires allison.desktop.sessions.hyprland.enable = true.'';
      }
    ];

    services.xserver.enable = true;

    services.displayManager = {
      defaultSession = cfg.defaultSession;

      gdm.enable = cfg.sessions.gnome.enable;
    };

    xdg.portal.enable = true;
    xdg.portal.xdgOpenUsePortal = true;

    services.power-profiles-daemon.enable = true;

    programs.dconf = lib.mkIf cfg.sessions.gnome.enable {
      enable = true;

      profiles.gdm.databases = lib.mkBefore [
        {
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
          };
        }
      ];
    };

    home-manager.users.allison.imports =
      lib.optionals cfg.sessions.gnome.enable [ ../home/allison/gnome.nix ]
      ++ lib.optionals cfg.sessions.hyprland.enable [ ../home/allison/hyprland.nix ];
  };
}

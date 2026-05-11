{ config, lib, pkgs, ... }:

let
  cfg = config.allison.desktop;
  wallpaper = ../../img/wallpaper/oilPainting.jpg;
  wallpaperPath = "${wallpaper}";
  wallpaperUri = "file://${wallpaperPath}";

  sddmTheme = pkgs.runCommand "allison-sddm-theme" { } ''
    theme_dir="$out/share/sddm/themes/allison-breeze"
    mkdir -p "$out/share/sddm/themes"
    cp -r ${pkgs.kdePackages.plasma-desktop}/share/sddm/themes/breeze "$theme_dir"
    chmod -R u+w "$theme_dir"
    sed -i 's|^background=.*|background=${wallpaperPath}|' "$theme_dir/theme.conf"
  '';
in
{
  options.allison.desktop = {
    defaultSession = lib.mkOption {
      type = lib.types.enum [ "gnome" "plasma" "plasmax11" ];
      default = "gnome";
      description = "Desktop session SDDM should select by default.";
    };

    sessions = {
      gnome.enable = lib.mkEnableOption "GNOME desktop session" // {
        default = true;
      };

      plasma.enable = lib.mkEnableOption "Plasma desktop session";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.sessions.gnome.enable || cfg.sessions.plasma.enable;
        message = "At least one desktop session must be enabled.";
      }
      {
        assertion = cfg.defaultSession != "gnome" || cfg.sessions.gnome.enable;
        message = ''allison.desktop.defaultSession = "gnome" requires allison.desktop.sessions.gnome.enable = true.'';
      }
      {
        assertion = !(lib.elem cfg.defaultSession [ "plasma" "plasmax11" ]) || cfg.sessions.plasma.enable;
        message = ''Plasma default sessions require allison.desktop.sessions.plasma.enable = true.'';
      }
    ];

    services.xserver.enable = true;

    services.displayManager = {
      defaultSession = cfg.defaultSession;

      gdm.enable = cfg.sessions.gnome.enable;

      sddm = {
        enable = cfg.sessions.plasma.enable && !cfg.sessions.gnome.enable;
        theme = "allison-breeze";
        wayland.enable = true;
        extraPackages = with pkgs.kdePackages; [
          kirigami
          plasma-desktop
          plasma-workspace
          qqc2-breeze-style
        ];
      };
    };

    environment.systemPackages = lib.optionals cfg.sessions.plasma.enable [ sddmTheme ];

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
      ++ lib.optionals cfg.sessions.plasma.enable [ ../home/allison/plasma.nix ];
  };
}

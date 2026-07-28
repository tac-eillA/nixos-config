{ lib, pkgs, ... }:

let
  wallpaper = ../../../img/wallpaper/oilPainting.jpg;
  terminal = "ghostty";
  browser = "firefox";
  fileManager = "nautilus";
in
{
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
  };

  home.packages = with pkgs; [
    bibata-cursors
    blueman
    grimblast
    hypridle
    hyprlock
    hyprpaper
    libnotify
    networkmanagerapplet
    pavucontrol
    playerctl
    swaynotificationcenter
    wlogout
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

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = terminal;
      "$browser" = browser;
      "$fileManager" = fileManager;

      monitor = [ ",preferred,auto,1" ];

      exec-once = [
        "waybar"
        "nm-applet --indicator"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(8aadf4ee) rgba(c6a0f6ee) 45deg";
        "col.inactive_border" = "rgba(494d64aa)";
        layout = "dwindle";
        resize_on_border = true;
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 0.96;
        shadow = {
          enabled = true;
          range = 12;
          render_power = 3;
          color = "rgba(00000066)";
        };
        blur = {
          enabled = true;
          size = 7;
          passes = 3;
          vibrancy = 0.2;
        };
      };

      animations = {
        enabled = true;
        bezier = [ "easeOut,0.16,1,0.3,1" ];
        animation = [
          "windows,1,4,easeOut,popin 80%"
          "windowsOut,1,4,easeOut,popin 80%"
          "fade,1,4,easeOut"
          "workspaces,1,4,easeOut,slide"
        ];
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      workspace = map (number: "${toString number}, persistent:true") (lib.range 1 5);

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, B, exec, $browser"
        "$mod, E, exec, $fileManager"
        "$mod, Space, exec, vicinae toggle"
        "$mod, N, exec, swaync-client -t -sw"
        "$mod SHIFT, E, exec, wlogout"
        "$mod, Q, killactive"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"

        "$mod, H, movefocus, l"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"
        "$mod, L, movefocus, r"
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, J, movewindow, d"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, L, movewindow, r"

        ", Print, exec, grimblast copy area"
        "SHIFT, Print, exec, grimblast save area"
        "$mod, Escape, exec, loginctl lock-session"

        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ]
      ++ map (number: "$mod, ${toString number}, workspace, ${toString number}") (lib.range 1 5)
      ++ map (number: "$mod SHIFT, ${toString number}, movetoworkspace, ${toString number}") (lib.range 1 5);

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      gesture = [
        "3, horizontal, workspace"
      ];

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        focus_on_activate = true;
      };
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "${wallpaper}" ];
      wallpaper = [ ",${wallpaper}" ];
      splash = false;
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
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

  programs.waybar = {
    enable = true;
    systemd.enable = false;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      spacing = 4;
      modules-left = [
        "hyprland/workspaces"
        "hyprland/window"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "custom/notifications"
        "tray"
        "network"
        "bluetooth"
        "pulseaudio"
        "battery"
      ];
      "hyprland/workspaces" = {
        persistent-workspaces."*" = 5;
        format = "{name}";
        on-click = "activate";
      };
      "hyprland/window" = {
        format = "{title}";
        max-length = 60;
        separate-outputs = true;
      };
      clock = {
        format = "{:%a %b %d  %H:%M}";
        tooltip-format = "<big>{:%Y %B}</big>\\n<tt><small>{calendar}</small></tt>";
      };
      "custom/notifications" = {
        tooltip = false;
        format = "";
        on-click = "swaync-client -t -sw";
      };
      tray.spacing = 8;
      network = {
        format-wifi = "  {signalStrength}%";
        format-ethernet = "󰈀";
        format-disconnected = "󰤭";
        tooltip-format = "{ifname}: {ipaddr}";
        on-click = "nm-connection-editor";
      };
      bluetooth = {
        format = "";
        format-disabled = "";
        format-off = "";
        on-click = "blueman-manager";
      };
      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰖁";
        format-icons.default = [
          ""
          ""
          ""
        ];
        on-click = "pavucontrol";
      };
      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-icons = [
          "󰁺"
          "󰁼"
          "󰁾"
          "󰂀"
          "󰁹"
        ];
      };
    };
    style = ''
      * {
        font-family: "Adwaita Sans", "Symbols Nerd Font";
        font-size: 13px;
        min-height: 0;
      }
      window#waybar {
        background: rgba(30, 32, 48, 0.94);
        color: #cad3f5;
        border-bottom: 1px solid rgba(138, 173, 244, 0.35);
      }
      #workspaces button {
        color: #a5adcb;
        padding: 0 10px;
        border-radius: 0;
      }
      #workspaces button.active {
        color: #8aadf4;
        background: rgba(138, 173, 244, 0.16);
        box-shadow: inset 0 -2px #8aadf4;
      }
      #window { padding-left: 10px; }
      #clock, #custom-notifications, #tray, #network, #bluetooth,
      #pulseaudio, #battery {
        padding: 0 9px;
      }
      #battery.warning { color: #eed49f; }
      #battery.critical { color: #ed8796; }
    '';
  };

  services.swaync.enable = true;

  xdg.configFile."wlogout/layout".text = ''
    [
    {
      "label" : "lock",
      "action" : "loginctl lock-session",
      "text" : "Lock",
      "keybind" : "l"
    },
    {
      "label" : "logout",
      "action" : "uwsm stop",
      "text" : "Logout",
      "keybind" : "e"
    },
    {
      "label" : "suspend",
      "action" : "systemctl suspend",
      "text" : "Suspend",
      "keybind" : "s"
    },
    {
      "label" : "reboot",
      "action" : "systemctl reboot",
      "text" : "Reboot",
      "keybind" : "r"
    },
    {
      "label" : "shutdown",
      "action" : "systemctl poweroff",
      "text" : "Shutdown",
      "keybind" : "p"
    }
    ]
  '';
}

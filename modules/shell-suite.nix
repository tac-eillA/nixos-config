{ lib, pkgs, vars, ... }:
let
  hasElephant = pkgs ? elephant;
  defaultUserTarget = [ "default.target" ];
  timerTarget = [ "timers.target" ];
  repoRoot = (vars.paths or { }).repoRoot or "/etc/nixos";
in
{
  environment.systemPackages =
    (with pkgs; [
      walker
      cliphist
      wtype
      satty
      wf-recorder
      swayosd
      pywal
      jq
      libnotify
      pamixer
      upower
    ])
    ++ lib.optionals hasElephant [ pkgs.elephant ];

  services.swayosd.enable = true;

  systemd.user.services =
    {
      shell-walker = {
        description = "Walker launcher service";
        after = lib.optionals hasElephant [ "shell-elephant.service" ];
        wants = lib.optionals hasElephant [ "shell-elephant.service" ];
        wantedBy = defaultUserTarget;
        serviceConfig = {
          ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
          Restart = "on-failure";
          RestartSec = 1;
        };
      };

      shell-cliphist-text = {
        description = "Clipboard history watcher (text)";
        wantedBy = defaultUserTarget;
        serviceConfig = {
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "always";
          RestartSec = 1;
        };
      };

      shell-cliphist-image = {
        description = "Clipboard history watcher (image)";
        wantedBy = defaultUserTarget;
        serviceConfig = {
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "always";
          RestartSec = 1;
        };
      };

      shell-battery-monitor = {
        description = "Battery monitor check";
        wantedBy = defaultUserTarget;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "%h/.config/shell/bin/shell-battery-monitor";
        };
      };

      shell-update-check = {
        description = "Update availability check";
        wantedBy = defaultUserTarget;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "%h/.config/shell/bin/shell-update-check";
          Environment = [ "NIXOS_CONFIG_REPO=${repoRoot}" ];
        };
      };
    }
    // lib.optionalAttrs hasElephant {
      shell-elephant = {
        description = "Shell provider service";
        wantedBy = defaultUserTarget;
        serviceConfig = {
          ExecStart = "${pkgs.elephant}/bin/elephant";
          Restart = "on-failure";
          RestartSec = 1;
        };
      };
    };

  systemd.user.timers.shell-battery-monitor = {
    description = "Battery monitor timer";
    wantedBy = timerTarget;
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "45s";
      AccuracySec = "10s";
      Unit = "shell-battery-monitor.service";
    };
  };

  systemd.user.timers.shell-update-check = {
    description = "Update check timer";
    wantedBy = timerTarget;
    timerConfig = {
      OnBootSec = "10m";
      OnUnitActiveSec = "6h";
      AccuracySec = "5m";
      Unit = "shell-update-check.service";
    };
  };
}

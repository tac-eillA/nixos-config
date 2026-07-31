{ lib, ... }:

let
  inherit (lib) mkOption types;

  displayRuleType = types.submodule {
    options = {
      output = mkOption {
        type = types.str;
        description = "Hyprland output name.";
      };

      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Whether this output is enabled by the profile.";
      };

      mode = mkOption {
        type = types.str;
        default = "preferred";
        description = "Hyprland output mode, for example preferred or 2560x1440@120.";
      };

      position = mkOption {
        type = types.str;
        default = "auto";
        description = "Hyprland output position, for example auto or 0x0.";
      };

      scale = mkOption {
        type = types.float;
        default = 1.0;
        description = "Output scale.";
      };

      transform = mkOption {
        type = types.ints.between 0 7;
        default = 0;
        description = "Hyprland output transform.";
      };

      vrr = mkOption {
        type = types.ints.between 0 3;
        default = 0;
        description = "Per-output variable refresh-rate policy.";
      };

      mirror = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Output to mirror, or null for an independent output.";
      };
    };
  };

  adaptiveProfileType = types.submodule {
    options = {
      priority = mkOption {
        type = types.int;
        default = 0;
        description = "Profile selection priority; higher values win.";
      };

      manualOnly = mkOption {
        type = types.bool;
        default = false;
        description = "Only select this profile through an explicit shell action.";
      };

      match = {
        onBattery = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Require battery or AC power when non-null.";
        };

        externalMonitor = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Require an enabled external monitor when non-null.";
        };

        tabletMode = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Require tablet mode when non-null.";
        };
      };

      displayProfile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Named display profile to apply when this profile activates.";
      };

      powerProfile = mkOption {
        type = types.nullOr (types.enum [ "power-saver" "balanced" "performance" ]);
        default = null;
        description = "power-profiles-daemon profile to request.";
      };

      animations = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether Hyprland animations should be enabled.";
      };

      maxRefreshRate = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Maximum refresh rate for the internal panel.";
      };

      idleInhibit = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether the shell should inhibit idle.";
      };

      doNotDisturb = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether notification popups should be suppressed.";
      };

      touchLayout = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether the shell should use touch-sized controls.";
      };
    };
  };
in
{
  options.scylla.desktop.shell = {
    internalDisplay = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Internal panel used by refresh-rate and dock policy, or null on desktops.";
    };

    tabletModePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional sysfs file whose value is 1 while tablet mode is active.";
    };

    displayProfiles = mkOption {
      type = types.attrsOf (types.listOf displayRuleType);
      default = { };
      description = "Declarative named monitor profiles available to the desktop shell.";
    };

    adaptive = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable hardware-adaptive shell policy.";
      };

      profiles = mkOption {
        type = types.attrsOf adaptiveProfileType;
        default = {
          ac = {
            priority = 0;
            match.onBattery = false;
            powerProfile = "balanced";
            animations = true;
          };
          battery = {
            priority = 10;
            match.onBattery = true;
            powerProfile = "power-saver";
            animations = false;
            maxRefreshRate = 60;
          };
          docked = {
            priority = 20;
            match.externalMonitor = true;
            powerProfile = "balanced";
            animations = true;
          };
          presentation = {
            priority = 100;
            manualOnly = true;
            powerProfile = "balanced";
            animations = true;
            idleInhibit = true;
            doNotDisturb = true;
          };
          tablet = {
            priority = 90;
            match.tabletMode = true;
            touchLayout = true;
          };
        };
        description = "Declarative adaptive profiles evaluated by the shell.";
      };
    };
  };
}

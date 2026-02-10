{ lib, config, pkgs, ... }:
let
  cfg = config.artemis.profiles.framework13;
in
{
  options.artemis.profiles.framework13.enable = lib.mkEnableOption "Framework 13 AMD laptop tuning";

  config = lib.mkIf cfg.enable {
    hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

    boot.kernelParams = [
      "amd_pstate=active"
    ];

    powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";
    services.power-profiles-daemon.enable = lib.mkForce false;
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "low-power";
        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "auto";
        USB_AUTOSUSPEND = "1";
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";
      };
    };

    environment.systemPackages = [ pkgs.tlp ];

    services.logind = {
      lidSwitch = lib.mkDefault "suspend";
      lidSwitchDocked = lib.mkDefault "ignore";
      lidSwitchExternalPower = lib.mkDefault "ignore";
    };
  };
}

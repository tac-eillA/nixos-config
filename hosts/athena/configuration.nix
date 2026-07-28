{ inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ../../modules/profiles/workstation.nix
    #../../modules/dev/unreal.nix
  ];

  # Ryzen AI 300 firmware does not describe every device dependency needed
  # during a system-wide power transition. Serializing device suspend/resume
  # avoids intermittent input/USB/GPU resume hangs on this platform.
  boot.kernelParams = [ "pm_async=off" ];

  # Keep the pre-login UI on the laptop panel. Hyprland applies the user's
  # complete docked layout after SDDM launches the UWSM-managed session.
  allison.desktop.login.internalDisplayOnly = true;

  # programs.unrealEngine = {
  #     enable = true;
  #     user = "allison";

  #     # Use "nvidia" or "amd"
  #     # Use "generic" if unsure.
  #     gpu = "amd";

  #     engineRoot = "$HOME/src/UnrealEngine";
  #     projectsDir = "$HOME/UnrealProjects";
  #     engineRef = "release";
  #     jobs = null;
  #     enableSteamCompat = false;
  #     enableGamemode = true;
  #   };

  # programs.unrealEnginePrebuilt = {
  #     enable = true;
  #     user = "allison";

  #     # This is where ue-bin-install will place the extracted engine by default.
  #     engineRoot = "$HOME/Applications/UnrealEngine";

  #     projectsDir = "$HOME/UnrealProjects";

  #     # For athena, probably "nvidia" if that is your NVIDIA desktop.
  #     gpu = "nvidia";

  #     # Your repo already has gaming/dev modules, so these are safe defaults.
  #     enableCppTools = true;
  #     installCppToolsGlobally = false;
  #     enableGamemode = true;
  #     enableNixLd = true;
  #     enableGraphics = true;
  #     enableAudio = true;
  #   };

  networking.hostName = "athena";
}

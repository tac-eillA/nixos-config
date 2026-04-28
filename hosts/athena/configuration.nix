{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
    ../../modules/dev/unreal.nix
  ];

  programs.unrealEngine = {
      enable = true;
      user = "allison";

      # Use "nvidia" or "amd"
      # Use "generic" if unsure.
      gpu = "amd";

      engineRoot = "$HOME/src/UnrealEngine";
      projectsDir = "$HOME/UnrealProjects";
      engineRef = "release";
      jobs = null;
      enableSteamCompat = false;
      enableGamemode = true;
    };

  networking.hostName = "athena";
}

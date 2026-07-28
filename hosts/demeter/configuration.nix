{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
    #../../modules/dev/unreal.nix
  ];

  allison.desktop.video.gpu = "nvidia";

  # programs.unrealEngine = {
  #     enable = true;
  #     user = "allison";

  #     # Use "nvidia" or "amd"
  #     # Use "generic" if unsure.
  #     gpu = "nvidia";

  #     engineRoot = "$HOME/src/UnrealEngine";
  #     projectsDir = "$HOME/UnrealProjects";
  #     engineRef = "release";
  #     jobs = null;
  #     enableSteamCompat = false;
  #     enableGamemode = true;
  #   };

  networking.hostName = "demeter";
}

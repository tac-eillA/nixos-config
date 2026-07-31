{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    #../../modules/features/development/unreal.nix
  ];

  scylla.desktop.video.gpu = "nvidia";

  # programs.unrealEngine = {
  #     enable = true;
  #     user = "scylla";

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
}

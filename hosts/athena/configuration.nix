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

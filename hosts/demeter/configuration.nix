{ pkgs, ... }:

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
      gpu = "nvidia";

      engineRoot = "$HOME/src/UnrealEngine";
      projectsDir = "$HOME/UnrealProjects";
      engineRef = "release";
      jobs = null;
      enableSteamCompat = false;
      enableGamemode = true;
    };

  networking.hostName = "demeter";

  systemd.services.plasmalogin.preStart = ''
    ${pkgs.coreutils}/bin/install -Dm600 \
      -o plasmalogin \
      -g plasmalogin \
      ${./kwinoutputconfig.json} \
      /var/lib/plasmalogin/.config/kwinoutputconfig.json
  '';
}

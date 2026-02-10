{ lib, config, pkgs, ... }:
let
  cfg = config.artemis.profiles.gaming;
in
{
  options.artemis.profiles.gaming.enable = lib.mkEnableOption "gaming stack (Steam, tools, runtime bits)";

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.steam-hardware.enable = true;

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = false;
      gamescopeSession.enable = true;
    };

    programs.gamemode.enable = true;
    programs.gamescope.enable = true;

    environment.systemPackages = with pkgs; [
      lutris
      mangohud
      protontricks
      winetricks
      wineWowPackages.stable
      vulkan-tools
    ];
  };
}

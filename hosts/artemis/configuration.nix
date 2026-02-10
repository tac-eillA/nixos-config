{ pkgs, vars, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/boot-storage.nix
    ../../modules/services-core.nix
    ../../modules/packages-core.nix
    ../../modules/desktop-niri.nix
    ../../modules/shell-suite.nix
    ../../modules/dotfiles-link.nix
    ../../modules/profile-framework13-amd.nix
    ../../modules/profile-nvidia-desktop.nix
    ../../modules/profile-gaming.nix
  ];

  networking.hostName = vars.host.name or "artemis";

  artemis.profiles = {
    framework13.enable = vars.profiles.framework13 or false;
    nvidiaDesktop.enable = vars.profiles.nvidiaDesktop or false;
    gaming.enable = vars.profiles.gaming or false;
  };

  users.users.${vars.user.name} = {
    isNormalUser = true;
    description = vars.user.fullName or vars.user.name;
    extraGroups =
      vars.user.extraGroups
      or [
        "wheel"
        "networkmanager"
        "audio"
        "video"
        "docker"
      ];
    shell = pkgs.zsh;
    initialPassword = vars.user.initialPassword or "changeme";
  };

  nixpkgs.hostPlatform = vars.host.system or "x86_64-linux";
  system.stateVersion = vars.host.stateVersion or "25.11";
}

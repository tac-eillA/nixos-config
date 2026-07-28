{ config, lib, pkgs, ... }:

let
  cfg = config.scylla.user;
  homeDirectory =
    if cfg.homeDirectory == null
    then "/home/${cfg.name}"
    else cfg.homeDirectory;
in
{
  options.scylla.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "allison";
      description = "Primary local user managed by the Scylla configuration.";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Allison Snodgrass";
      description = "Display name for the primary local user.";
    };

    homeDirectory = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Primary user's home directory; null uses /home/<name>.";
    };

    git = {
      name = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "Allison Snodgrass";
        description = "Git author name; null leaves it unset.";
      };

      email = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "email@allie.is";
        description = "Git author email; null leaves it unset.";
      };
    };
  };

  config = {
    users.users.${cfg.name} = {
      isNormalUser = true;
      description = cfg.fullName;
      home = homeDirectory;
      extraGroups = [ "wheel" "networkmanager" "nordvpn" "netbird" ];
      shell = pkgs.zsh;
    };

    home-manager.users.${cfg.name} = import ../home/scylla;
  };
}

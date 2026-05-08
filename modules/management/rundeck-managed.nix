{ config, lib, pkgs, ... }:

let
  cfg = config.management.rundeckManaged;
in
{
  options.management.rundeckManaged = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable this host as a Rundeck-managed SSH target.";
    };

    publicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys allowed to log in as the Rundeck automation user.";
    };

    passwordHashFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Runtime path containing the hashed password for prompted sudo.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh.enable = true;

    users.users.rundeck = {
      isNormalUser = true;
      description = "Rundeck remote automation user";
      home = "/var/lib/rundeck-managed";
      createHome = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.bashInteractive;
      hashedPasswordFile = cfg.passwordHashFile;

      openssh.authorizedKeys.keys = cfg.publicKeys;
    };
  };
}

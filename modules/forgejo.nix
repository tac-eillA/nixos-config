{ config, lib, pkgs, ... }:

let
  cfg = config.services.forgejo;
  domain = "git.allie.sh";
  httpsPort = 3000;
in
{
  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;

    database = {
      type = "postgres";
    };

    lfs.enable = true;

    settings = {
      server = {
        DOMAIN = domain;
        ROOT_URL = "https://${domain}/";
        HTTPS_ADDR = "0.0.0.0";
        HTTPS_PORT = httpPort;

        START_SSH_SERVER = false;
        SSH_PORT = lib.head config.services.openssh.ports;
      };

      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = false;
      };

      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
      };

      repository = {
        DEFAULT_BRANCH = "main";
      };

      security = {
        INSTALL_LOCK = true;
      };

      session = {
        COOKIE_SECURE = false;
      };
    };
  };

  services.postgresql.enable = true;
  services.qemuGuest.enable = true;
  services.openssh.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
    ];
  };

  environment.systemPackages = with pkgs; [
    forgejo-cli
    forgejo
  ];
}

{ config, lib, ... }:

let
  cfg = config.scylla.roles.paperless-ngx;
  passwordFile = config.sops.secrets."paperless/admin-password".path;
  paperlessUnits = [
    "paperless-consumer.service"
    "paperless-scheduler.service"
    "paperless-task-queue.service"
    "paperless-web.service"
  ];
in
{
  options.scylla.roles.paperless-ngx = {
    enable = lib.mkEnableOption "the Paperless-ngx workload";

    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "paperless.allie.sh";
      description = "Public Paperless-ngx domain.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "0.0.0.0";
      description = "Address on which Paperless-ngx listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 28981;
      description = "Paperless-ngx HTTP port.";
    };

    installAdminPackages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to install the Paperless management command globally.";
    };

    secretFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/paperless.yaml;
      description = "SOPS file containing the Paperless administrator password.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.pathExists cfg.secretFile;
        message = "The Paperless-ngx role secret file does not exist.";
      }
    ];

    sops.age = {
      keyFile = "/var/lib/sops-nix/age-key.txt";
      generateKey = false;
    };

    sops.secrets."paperless/admin-password" = {
      sopsFile = cfg.secretFile;
      owner = "paperless";
      group = "paperless";
      mode = "0400";
      restartUnits = paperlessUnits;
    };

    services.paperless = {
      enable = true;
      address = cfg.listenAddress;
      inherit (cfg) domain port;
      inherit passwordFile;
      database.createLocally = true;
      configureTika = true;

      settings = {
        PAPERLESS_OCR_LANGUAGE = "eng";
        PAPERLESS_CONSUMER_RECURSIVE = true;
      };
    };

    environment.systemPackages = lib.optionals cfg.installAdminPackages [
      config.services.paperless.manage
    ];
  };
}

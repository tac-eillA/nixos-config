{ config, lib, pkgs, ... }:

let
  cfg = config.scylla.roles.authentik;
  authentikContainers = [
    "podman-authentik-postgres.service"
    "podman-authentik-redis.service"
    "podman-authentik-server.service"
    "podman-authentik-worker.service"
  ];
  authentikEnv = config.sops.secrets."authentik/env".path;
in
{
  options.scylla.roles.authentik = {
    enable = lib.mkEnableOption "the Authentik workload";

    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "auth.allie.sh";
      description = "Public Authentik domain.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "0.0.0.0";
      description = "Address on which the Authentik reverse proxy listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9000;
      description = "Public Authentik reverse-proxy port.";
    };

    backendAddress = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "127.0.0.1";
      description = "Address on which the Authentik container is published.";
    };

    backendPort = lib.mkOption {
      type = lib.types.port;
      default = 9001;
      description = "Host port mapped to the Authentik server container.";
    };

    networkName = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "authentik";
      description = "Podman network shared by the Authentik containers.";
    };

    postgresImage = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "docker.io/library/postgres:16-alpine";
      description = "PostgreSQL container image.";
    };

    redisImage = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "docker.io/library/redis:alpine";
      description = "Redis container image.";
    };

    serverImage = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "ghcr.io/goauthentik/server:2026.2.2";
      description = "Authentik server and worker container image.";
    };

    installAdminPackages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to install Podman administration tools globally.";
    };

    secretFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/authentik.yaml;
      description = "SOPS file containing the Authentik environment.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.pathExists cfg.secretFile;
        message = "The Authentik role secret file does not exist.";
      }
      {
        assertion = cfg.backendAddress != cfg.listenAddress || cfg.backendPort != cfg.port;
        message = "Authentik's backend and public listener cannot use the same socket.";
      }
    ];

    sops.age = {
      keyFile = "/var/lib/sops-nix/age-key.txt";
      generateKey = false;
    };

    sops.secrets."authentik/env" = {
      sopsFile = cfg.secretFile;
      mode = "0400";
      restartUnits = authentikContainers;
    };

    virtualisation.oci-containers.backend = "podman";

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };

    virtualisation.oci-containers.containers = {
      authentik-postgres = {
        image = cfg.postgresImage;
        autoStart = true;
        extraOptions = [ "--network=${cfg.networkName}" ];
        environment = {
          POSTGRES_DB = "authentik";
          POSTGRES_USER = "authentik";
        };
        environmentFiles = [ authentikEnv ];
        volumes = [ "authentik-postgres:/var/lib/postgresql/data" ];
      };

      authentik-redis = {
        image = cfg.redisImage;
        autoStart = true;
        extraOptions = [ "--network=${cfg.networkName}" ];
        cmd = [
          "redis-server"
          "--save"
          "60"
          "1"
          "--loglevel"
          "warning"
        ];
        volumes = [ "authentik-redis:/data" ];
      };

      authentik-server = {
        image = cfg.serverImage;
        autoStart = true;
        extraOptions = [ "--network=${cfg.networkName}" ];
        ports = [ "${cfg.backendAddress}:${toString cfg.backendPort}:9000" ];
        environment = {
          AUTHENTIK_REDIS__HOST = "authentik-redis";
          AUTHENTIK_POSTGRESQL__HOST = "authentik-postgres";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
          AUTHENTIK_ERROR_REPORTING__ENABLED = "false";
        };
        environmentFiles = [ authentikEnv ];
        dependsOn = [
          "authentik-postgres"
          "authentik-redis"
        ];
        cmd = [ "server" ];
      };

      authentik-worker = {
        image = cfg.serverImage;
        autoStart = true;
        extraOptions = [ "--network=${cfg.networkName}" ];
        environment = {
          AUTHENTIK_REDIS__HOST = "authentik-redis";
          AUTHENTIK_POSTGRESQL__HOST = "authentik-postgres";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
          AUTHENTIK_ERROR_REPORTING__ENABLED = "false";
        };
        environmentFiles = [ authentikEnv ];
        dependsOn = [
          "authentik-postgres"
          "authentik-redis"
        ];
        cmd = [ "worker" ];
      };
    };

    systemd.services.authentik-podman-network = {
      description = "Create Authentik Podman network";
      wantedBy = [ "multi-user.target" ];
      requiredBy = authentikContainers;
      before = authentikContainers;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.podman}/bin/podman network exists ${lib.escapeShellArg cfg.networkName} || \
        ${pkgs.podman}/bin/podman network create ${lib.escapeShellArg cfg.networkName}
      '';
    };

    services.nginx = {
      enable = true;

      virtualHosts.${cfg.domain} = {
        listen = [
          {
            addr = cfg.listenAddress;
            port = cfg.port;
          }
        ];

        locations."/" = {
          proxyPass = "http://${cfg.backendAddress}:${toString cfg.backendPort}";
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_set_header X-Forwarded-Proto https;
          '';
        };
      };
    };

    environment.systemPackages = lib.optionals cfg.installAdminPackages (
      with pkgs;
      [
        podman
        podman-compose
        openssl
      ]
    );
  };
}

{ config, lib, pkgs, ... }:

let
  domain = "auth.allie.sh";

  authentikEnv = "/var/lib/secrets/authentik.env";
in
{
  virtualisation.oci-containers.backend = "podman";

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  virtualisation.oci-containers.containers = {
    authentik-postgres = {
      image = "docker.io/library/postgres:16-alpine";
      autoStart = true;
      extraOptions = [ "--network=authentik" ];
      environment = {
        POSTGRES_DB = "authentik";
        POSTGRES_USER = "authentik";
      };
      environmentFiles = [ authentikEnv ];
      volumes = [
        "authentik-postgres:/var/lib/postgresql/data"
      ];
    };

    authentik-redis = {
      image = "docker.io/library/redis:alpine";
      autoStart = true;
      extraOptions = [ "--network=authentik" ];
      cmd = [ "redis-server" "--save" "60" "1" "--loglevel" "warning" ];
      volumes = [
        "authentik-redis:/data"
      ];
    };

    authentik-server = {
      image = "ghcr.io/goauthentik/server:latest";
      autoStart = true;
      extraOptions = [ "--network=authentik" ];

      ports = [
        "9000:9000"
      ];

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
      image = "ghcr.io/goauthentik/server:latest";
      autoStart = true;
      extraOptions = [ "--network=authentik" ];

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

    wantedBy = [
      "podman-authentik-postgres.service"
      "podman-authentik-redis.service"
      "podman-authentik-server.service"
      "podman-authentik-worker.service"
    ];

    before = [
      "podman-authentik-postgres.service"
      "podman-authentik-redis.service"
      "podman-authentik-server.service"
      "podman-authentik-worker.service"
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      ${pkgs.podman}/bin/podman network exists authentik || \
      ${pkgs.podman}/bin/podman network create authentik
    '';
  };

  services.openssh.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      9000
      22
    ];
  };

  environment.systemPackages = with pkgs; [
    podman
    podman-compose
  ];
}

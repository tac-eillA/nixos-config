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
      cmd = [ "redis-server" "--save" "60" "1" "--loglevel" "warning" ];
      volumes = [
        "authentik-redis:/data"
      ];
    };

    authentik-server = {
      image = "ghcr.io/goauthentik/server:latest";
      autoStart = true;

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

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 9000 ];
  };

  environment.systemPackages = with pkgs; [
    podman
    podman-compose
    openssl
  ];
}

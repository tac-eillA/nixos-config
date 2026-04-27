{ pkgs, ... }:

let
  domain = "auth.allie.sh";
  authentikUpstream = "http://127.0.0.1:9001";
  authentikContainers = [
    "podman-authentik-postgres.service"
    "podman-authentik-redis.service"
    "podman-authentik-server.service"
    "podman-authentik-worker.service"
  ];
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
      image = "ghcr.io/goauthentik/server:2026.2.2";
      autoStart = true;
      extraOptions = [ "--network=authentik" ];

      ports = [
        "127.0.0.1:9001:9000"
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
      image = "ghcr.io/goauthentik/server:2026.2.2";
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

    wantedBy = [ "multi-user.target" ];
    requiredBy = authentikContainers;
    before = authentikContainers;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      ${pkgs.podman}/bin/podman network exists authentik || \
      ${pkgs.podman}/bin/podman network create authentik
    '';
  };

  services.nginx = {
    enable = true;

    virtualHosts.${domain} = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 9000;
        }
      ];

      locations."/" = {
        proxyPass = authentikUpstream;
        recommendedProxySettings = true;
        extraConfig = ''
          proxy_set_header X-Forwarded-Proto https;
        '';
      };

      locations."= /application/o/netbird/.well-known/openid-configuration" = {
        proxyPass = "${authentikUpstream}/application/o/netbird/.well-known/openid-configuration";
        recommendedProxySettings = true;
        extraConfig = ''
          proxy_set_header X-Forwarded-Proto https;
          proxy_hide_header Access-Control-Allow-Origin;
          proxy_hide_header Access-Control-Allow-Methods;
          proxy_hide_header Access-Control-Allow-Headers;
          add_header Access-Control-Allow-Origin "https://netbird.allie.sh" always;
          add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
          add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
          if ($request_method = OPTIONS) {
            return 204;
          }
        '';
      };

      locations."= /application/o/netbird/jwks/" = {
        proxyPass = "${authentikUpstream}/application/o/netbird/jwks/";
        recommendedProxySettings = true;
        extraConfig = ''
          proxy_set_header X-Forwarded-Proto https;
          proxy_hide_header Access-Control-Allow-Origin;
          proxy_hide_header Access-Control-Allow-Methods;
          proxy_hide_header Access-Control-Allow-Headers;
          add_header Access-Control-Allow-Origin "https://netbird.allie.sh" always;
          add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
          add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
          if ($request_method = OPTIONS) {
            return 204;
          }
        '';
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      22
      9000
    ];
  };

  environment.systemPackages = with pkgs; [
    podman
    podman-compose
    openssl
  ];
}

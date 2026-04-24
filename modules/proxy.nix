{ config, lib, pkgs, ... }:

let
  domain = "allie.sh";

  forgejoHost = "10.254.1.75";
  netbirdHost = "10.254.1.170";
  haosHost = "10.254.1.251";
  authHost = "10.254.1.163";
in
{
  services.qemuGuest.enable = true;

  services.cloudflared = {
      enable = true;
      tunnels = {
        "8eaa3da2-b2ae-4cbf-86f0-73bda6de85bd" = {
          credentialsFile = "~/.cloudflared/";
          ingress = {
            "git.allie.sh" = {
              service = "http://${forgejoHost}:3000";
              path = "/*.(jpg|png|css|js)";
            };
            "netbird.allie.sh" = {
              service = "http://${netbirdHost}:80";
              path = "/*.(jpg|png|css|js)";
            };
            "auth.allie.sh" = {
              service = "10.254.1.163";
              path = "/*.(jpg|png|css|js)";
            };
          };
          default = "http_status:404";
        };
      };
    };

  services.openssh.enable = true;
  services.caddy = {
    enable = true;

    # Optional, but useful for ACME / Let's Encrypt account notices.
    email = "email@allie.is";

    virtualHosts = {
      "git.${domain}" = {
        extraConfig = ''
          encode gzip zstd

          reverse_proxy http://${forgejoHost}:3000 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };

      "netbird.${domain}" = {
        extraConfig = ''
          encode gzip zstd

          reverse_proxy http://${netbirdHost}:80 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };

      "haos.${domain}" = {
        extraConfig = ''q
          encode gzip zstd

          reverse_proxy http://${haosHost}:8123 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };

      "auth.${domain}" = {
        extraConfig = ''
          encode gzip zstd

          reverse_proxy http://${authHost}:9000 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      443
      80
      22
    ];
  };

  environment.systemPackages = with pkgs; [
    caddy
    cloudflared
  ];
}

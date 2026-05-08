{ config, pkgs, ... }:

let
  domain = "headscale.allie.sh";
  authDomain = "auth.allie.sh";
  authApplication = "headscale";
  httpPort = 8080;
  oidcClientSecretFile = config.sops.secrets."headscale/authentik-client-secret".path;
in
{
  sops.secrets."headscale/authentik-client-secret" = {
    sopsFile = ../../secrets/headscale.yaml;
    owner = "headscale";
    group = "headscale";
    mode = "0400";
  };

  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = httpPort;

    settings = {
      server_url = "https://${domain}";

      dns = {
        magic_dns = true;
        base_domain = "tailnet.allie.sh";
        override_local_dns = false;
      };

      oidc = {
        issuer = "https://${authDomain}/application/o/${authApplication}/";
        client_id = authApplication;
        client_secret_path = oidcClientSecretFile;
        pkce.enabled = true;
      };
    };
  };

  services.nginx = {
    enable = true;

    virtualHosts.${domain} = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString httpPort}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          proxy_set_header X-Forwarded-Proto https;
        '';
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      22
      80
    ];
  };

  environment.systemPackages = with pkgs; [
    headscale
  ];
}

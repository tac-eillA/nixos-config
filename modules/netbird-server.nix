# modules/netbird-server.nix
{ pkgs, ... }:

let
  domain = "netbird.allie.sh";
  coturnPasswordFile = "/var/lib/secrets/netbird-coturn-password";
in
{
  services.qemuGuest.enable = true;
  services.netbird.server = {
    enable = true;
    enableNginx = true;

    domain = domain;

    coturn = {
      enable = true;
      domain = domain;
      passwordFile = coturnPasswordFile;
    };

    management = {
      # Replace this with your IdP OIDC discovery URL.
      # Examples: Authentik, Keycloak, Zitadel, Auth0, etc.
      #oidcConfigEndpoint = "https://auth.allie.sh/application/o/netbird/.well-known/openid-configuration";

      settings = {
        TURNConfig = {
          Turns = [
            {
              Proto = "udp";
              URI = "turn:${domain}:3478";
              Username = "netbird";
              Password._secret = coturnPasswordFile;
            }
          ];
        };
      };
    };
  };

  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      80
      443
      33073 # NetBird signal/management depending on proxy layout
      3478  # TURN TCP fallback
    ];

    allowedUDPPorts = [
      3478 # TURN UDP
    ];

    allowedUDPPortRanges = [
      {
        from = 49152;
        to = 65535;
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    netbird
  ];
}

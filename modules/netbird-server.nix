# modules/netbird-server.nix
{ pkgs, ... }:

let
  domain = "netbird.allie.sh";
  authDomain = "auth.allie.sh";
  coturnPasswordFile = "/home/allison/.netbird/netbird-coturn-password";
in
{
  services.qemuGuest.enable = true;
  services.openssh.enable = true;
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
      oidcConfigEndpoint = "https://${authDomain}/application/o/netbird/.well-known/openid-configuration";

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

    dashboard.settings = {
      AUTH_AUTHORITY = "https://${authDomain}/application/o/netbird/";
      AUTH_REDIRECT_URI = "/auth";
      AUTH_SILENT_REDIRECT_URI = "/silent-auth";
      AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
      NETBIRD_TOKEN_SOURCE = "accessToken";
    };
  };

  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      22
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
    netbird-ui
    openssl
  ];
}

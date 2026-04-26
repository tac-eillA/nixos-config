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
        credentialsFile = "/home/allison/.cloudflared/8eaa3da2-b2ae-4cbf-86f0-73bda6de85bd.json";
        warp-routing.enabled = true;
        ingress = {
          "git.allie.sh" = {
            service = "http://${forgejoHost}:3000";
            #path = "/*.(jpg|png|css|js)";
          };
          "netbird.allie.sh" = {
            service = "http://${netbirdHost}:80";
            #path = "/*.(jpg|png|css|js)";
          };
          "auth.allie.sh" = {
            service = "http://${authHost}:9000";
            #path = "/*.(jpg|png|css|js)";
          };
        };
        default = "http_status:404";
      };
    };
  };

  services.openssh.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      443
      80
      22
      3000
      9000
    ];
  };

  environment.systemPackages = with pkgs; [
    cloudflared
  ];
}

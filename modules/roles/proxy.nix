{ pkgs, ... }:

let
  forgejoHost = "10.254.1.75";
  netbirdHost = "10.254.1.170";
  authHost = "10.254.1.163";
  vaultwardenHost = "10.254.1.183";
  dns1Host = "10.254.1.171";
  dns2Host = "10.254.1.62";
in
{
  services.cloudflared = {
    enable = true;
    tunnels = {
      "8eaa3da2-b2ae-4cbf-86f0-73bda6de85bd" = {
        credentialsFile = "/home/allison/.cloudflared/8eaa3da2-b2ae-4cbf-86f0-73bda6de85bd.json";
        warp-routing.enabled = true;
        ingress = {
          "git.allie.sh" = {
            service = "http://${forgejoHost}:3000";
          };
          "netbird.allie.sh" = {
            service = "http://${netbirdHost}:80";
          };
          "auth.allie.sh" = {
            service = "http://${authHost}:9000";
          };
          "vault.allie.sh" = {
            service = "http://${vaultwardenHost}:8222";
          };
          "dns1-dash.allie.sh" = {
            service = "http://${dns1Host}:5380";
          };
          "dns2-dash.allie.sh" = {
            service = "http://${dns2Host}:5380";
          };
          "dns1.allie.sh" = {
            service = "http://${dns1Host}:53";
          };
          "dns2.allie.sh" = {
            service = "http://${dns2Host}:53";
          };
        };
        default = "http_status:404";
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      22
      53
      80
      443
      3000
      5380
      8222
      9000
    ];
  };

  environment.systemPackages = with pkgs; [
    cloudflared
  ];
}

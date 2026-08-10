{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
  ];

  networking.hostName = "proxy";
  systemd.network.networks."10-uplink".address = [ "10.254.1.215/24" ];

  scylla.roles.proxy = {
    enable = true;
    installAdminPackages = true;
    ingress = {
      "auth.allie.sh" = "http://10.254.1.210:9000";
      "dns1-dash.allie.sh" = "http://10.254.1.211:5380";
      "dns2-dash.allie.sh" = "http://10.254.1.212:5380";
      "git.allie.sh" = "http://10.254.1.213:3000";
      "headscale.allie.sh" = "http://10.254.1.214:80";
      "vault.allie.sh" = "http://10.254.1.216:8222";
    };
  };
}

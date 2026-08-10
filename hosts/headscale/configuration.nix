{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
  ];

  networking.hostName = "headscale";
  systemd.network.networks."10-uplink".address = [ "10.254.1.214/24" ];

  scylla.roles.headscale = {
    enable = true;
    domain = "headscale.allie.sh";
    listenAddress = "10.254.1.214";
    port = 80;
    oidcIssuer = "https://auth.allie.sh/application/o/headscale/";
    installAdminPackages = true;
  };

  scylla.network.exposures = [
    {
      name = "headscale";
      port = 80;
      protocols = [ "tcp" ];
      sources = [ "10.254.1.215/32" ];
    }
  ];
}

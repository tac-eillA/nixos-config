{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
  ];

  networking.hostName = "authentik";
  systemd.network.networks."10-uplink".address = [ "10.254.1.210/24" ];

  scylla.roles.authentik = {
    enable = true;
    domain = "auth.allie.sh";
    listenAddress = "10.254.1.210";
    port = 9000;
    installAdminPackages = true;
  };

  scylla.network.exposures = [
    {
      name = "authentik";
      port = 9000;
      protocols = [ "tcp" ];
      sources = [ "10.254.1.215/32" ];
    }
  ];
}

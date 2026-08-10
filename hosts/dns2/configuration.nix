{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
  ];

  networking.hostName = "dns2";
  systemd.network.networks."10-uplink".address = [ "10.254.1.212/24" ];

  scylla.roles.technitium-dns.enable = true;

  scylla.network.exposures = [
    {
      name = "dns2";
      port = 53;
      protocols = [
        "tcp"
        "udp"
      ];
      sources = [ "10.254.1.0/24" ];
    }
    {
      name = "dns2-dashboard";
      port = 5380;
      protocols = [ "tcp" ];
      sources = [ "10.254.1.215/32" ];
    }
  ];
}

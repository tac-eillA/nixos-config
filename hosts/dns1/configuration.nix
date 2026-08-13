{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
  ];

  networking.hostName = "dns1";
  systemd.network.networks."10-uplink".address = [ "10.254.1.211/24" ];

  scylla.roles.technitium-dns.enable = true;

  scylla.network.exposures = [
    {
      name = "dns1";
      port = 53;
      protocols = [
        "tcp"
        "udp"
      ];
      sources = [ "10.254.1.0/24" ];
    }
    {
      name = "dns1-dashboard";
      port = 5380;
      protocols = [ "tcp" ];
      sources = [ "100.64.0.0/10" ];
    }
  ];
}

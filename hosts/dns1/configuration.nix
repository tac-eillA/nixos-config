{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/technitium-dns
  ];

  networking.hostName = "dns1";

  systemd.network.networks."10-uplink".address = [ "10.254.1.211/24" ];
}

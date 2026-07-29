{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/technitium-dns
  ];

  networking.hostName = "dns2";

  systemd.network.networks."10-uplink".address = [ "10.254.1.212/24" ];
}

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/netbird-server.nix
  ];

  networking.hostName = "netbird";

  systemd.network.networks."10-uplink".address = [ "10.254.1.214/24" ];

}

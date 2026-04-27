{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/proxy.nix
  ];

  networking.hostName = "proxy";

  systemd.network.networks."10-uplink".address = [ "10.254.1.215/24" ];

}

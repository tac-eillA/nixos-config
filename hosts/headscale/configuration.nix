{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/headscale.nix
  ];

  networking.hostName = "headscale";

  systemd.network.networks."10-uplink".address = [ "10.254.1.214/24" ];

}

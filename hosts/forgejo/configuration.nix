{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/forgejo
  ];

  networking.hostName = "forgejo";

  systemd.network.networks."10-uplink".address = [ "10.254.1.213/24" ];

}

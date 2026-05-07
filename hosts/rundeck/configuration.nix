{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/rundeck.nix
  ];

  networking.hostName = "rundeck";

  systemd.network.networks."10-uplink".address = [ "10.254.1.217/24" ];
}

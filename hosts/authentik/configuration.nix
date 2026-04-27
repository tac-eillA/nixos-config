{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/authentik.nix
  ];

  networking.hostName = "authentik";

  systemd.network.networks."10-uplink".address = [ "10.254.1.210/24" ];

}

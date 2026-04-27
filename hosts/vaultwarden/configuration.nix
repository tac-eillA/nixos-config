{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/vaultwarden.nix
  ];

  networking.hostName = "vaultwarden";

  systemd.network.networks."10-uplink".address = [ "10.254.1.216/24" ];
}

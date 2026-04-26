{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/netbird-server.nix
  ];

  networking.hostName = "netbird";

}

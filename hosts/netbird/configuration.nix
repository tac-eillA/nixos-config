{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/netbird-server.nix
  ];

  networking.hostName = "netbird";

}

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
  ];

  networking.hostName = "netbird";

}

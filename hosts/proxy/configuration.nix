{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/proxy.nix
  ];

  networking.hostName = "proxy";

}

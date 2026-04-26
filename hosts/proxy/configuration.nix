{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/proxy.nix
  ];

  networking.hostName = "proxy";

}

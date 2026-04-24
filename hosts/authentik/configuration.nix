{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/authentik.nix
  ];

  networking.hostName = "authentik";

}

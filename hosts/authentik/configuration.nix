{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/authentik.nix
  ];

  networking.hostName = "authentik";

}

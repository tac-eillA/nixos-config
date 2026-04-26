{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/forgejo.nix
  ];

  networking.hostName = "forgejo";

}

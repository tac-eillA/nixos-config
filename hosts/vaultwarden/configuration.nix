{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/vaultwarden.nix
  ];

  networking.hostName = "vaultwarden";
}

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/roles/technitium-dns.nix
  ];

  networking.hostName = "dns2";
}

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
    ../../modules/technitium-dns.nix
  ];

  networking.hostName = "dns2";
}

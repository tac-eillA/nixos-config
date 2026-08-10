{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
  ];

  networking.hostName = "hera";
}

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/base.nix
  ];

  networking.hostName = "hera";
}

{ ... }:

{
  imports = [
    ./system.nix
    ./boot.nix
    ./network.nix
    ./firewall.nix
    ./shell.nix
    ./user.nix
  ];
}

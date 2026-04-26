{ ... }:

{
  imports = [
    ./system.nix
    ./boot.nix
    ./network.nix
    ./services.nix
    ./shell.nix
    ./user.nix
  ];
}

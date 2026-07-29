{ ... }:

{
  imports = [
    ../features/desktop.nix
    ../features/development/full.nix
    ../secrets/github.nix
    ../features/distrobox.nix
    ../features/gaming.nix
  ];
}

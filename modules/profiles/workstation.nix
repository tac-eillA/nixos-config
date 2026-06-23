{ ... }:

{
  imports = [
    ./desktop.nix
    ../dev/full.nix
    ../secrets/github.nix
    ../containers/distrobox.nix
    ../desktop/gaming.nix
  ];
}

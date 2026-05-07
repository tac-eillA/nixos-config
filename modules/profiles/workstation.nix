{ ... }:

{
  imports = [
    ./desktop.nix
    ../dev/full.nix
    ../containers/distrobox.nix
    ../desktop/gaming.nix
  ];
}

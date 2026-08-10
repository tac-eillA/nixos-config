{ inputs, pkgsStable, ... }:

{
  imports = [
    inputs."nix-flatpak".nixosModules.nix-flatpak
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops

    ../core
    ../features/appimage.nix
    ../features/audio.nix
    ../features/desktop.nix
    ../features/development/full.nix
    ../features/distrobox.nix
    ../features/firmware.nix
    ../features/gaming.nix
    ../features/printing.nix
    ../features/tailscale.nix
    ../features/tailscale-operator.nix
    ../secrets/github.nix
    ./workstation-user.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-home-manager";
    extraSpecialArgs = { inherit pkgsStable; };
  };
}

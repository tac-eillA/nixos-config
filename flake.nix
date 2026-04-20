{
  description = "Allie's systems nixos config";

  inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      nix-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
      nixos-hardware.url = "github:nixos/nixos-hardware";
      nix-flatpak.url = "github:gmodena/nix-flatpak";

      nur = {
        url = "github:nix-community/NUR";
        inputs.nixpkgs.follows = "nixpkgs";
      };
  };

  outputs = { self, nixpkgs, nur,  ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      mkPkgs = system: import nixpkgs {
        inherit system;
      };

      mkHost = hostname: lib.nixosSystem {
        inherit system;
        modules = [
          nur.modules.nixos.default
          ./hosts/${hostname}/configuration.nix
        ];
      };
    in {
      nixosConfigurations = {
        athena = mkHost "athena";
        artemis = mkHost "artemis";
        demeter = mkHost "demeter";
        hera = mkHost "hera";
        hestia = mkHost "hestia";
      };

      devShells.${system}.unreal =
        let pkgs = mkPkgs system;
        in import ./shells/unreal.nix { inherit pkgs; };

      formatter.${system} = (mkPkgs system).nixpkgs-fmt;
    };

}

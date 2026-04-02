{
  description = "Allie's systems nixos config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      mkPkgs = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      mkHost = hostname: lib.nixosSystem {
        inherit system;
        modules = [
          ./modules/common.nix
	  ./modules/plasma.nix
          ./modules/gamedev.nix
	  ./modules/utils.nix
	  ./modules/nvidia.nix
	  ./modules/zsh.nix
	  ./modules/printing.nix
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

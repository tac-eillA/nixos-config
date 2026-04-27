{
  description = "words are hard sometimes... i just want my systems to work how i tell them";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, nur, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      flatpakModule = inputs."nix-flatpak".nixosModules.nix-flatpak;

      mkPkgs = hostSystem: import nixpkgs {
        system = hostSystem;
      };

      mkHost = hostname: lib.nixosSystem {
        inherit system;
        modules = [
          nur.modules.nixos.default
          flatpakModule
          ./hosts/${hostname}/configuration.nix
        ];
      };
    in {
      nixosConfigurations = {
        athena = mkHost "athena";
        artemis = mkHost "artemis";
        demeter = mkHost "demeter";
        hera = mkHost "hera";
        hestia = mkHost "pythia";
        apollo = mkHost "apollo";
        dns1 = mkHost "dns1";
        dns2 = mkHost "dns2";
        forgejo = mkHost "forgejo";
        netbird = mkHost "netbird";
        authentik = mkHost "authentik";
        proxy = mkHost "proxy";
        vaultwarden = mkHost "vaultwarden";
      };

      devShells.${system}.unreal =
        let pkgs = mkPkgs system;
        in import ./shells/unreal.nix { inherit pkgs; };

      formatter.${system} = (mkPkgs system).nixpkgs-fmt;
    };
}

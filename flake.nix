{
  description = "Scylla — reusable NixOS configurations for my hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      mkHost =
        hostname:
        let
          pkgsStable = import inputs.nix-stable {
            inherit system;
            config.allowUnfree = true;
          };
        in
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs pkgsStable;
          };
          modules = [ ./hosts/${hostname}/configuration.nix ];
        };

      hostDirectories = builtins.readDir ./hosts;
      hostNames = lib.filter
        (
          hostname:
          hostDirectories.${hostname} == "directory"
          && builtins.pathExists (./hosts + "/${hostname}/configuration.nix")
        )
        (builtins.attrNames hostDirectories);
    in
    {
      nixosConfigurations = lib.genAttrs hostNames mkHost;

      templates = rec {
        default = host;
        host = {
          path = ./templates/host;
          description = "A share-safe Scylla host configuration";
        };
      };

      formatter.${system} = (import nixpkgs {
        inherit system;
      }).nixpkgs-fmt;
    };
}

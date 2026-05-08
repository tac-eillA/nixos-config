{
  description = "words are hard sometimes... i just want my systems to work how i tell them";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
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
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "before-home-manager";
            home-manager.users.allison = import ./modules/home/allison;
          }
          ./hosts/${hostname}/configuration.nix
        ];
      };
    in
    {
      nixosConfigurations = {
        athena = mkHost "athena";
        artemis = mkHost "artemis";
        demeter = mkHost "demeter";
        hera = mkHost "hera";
        pythia = mkHost "pythia";
        apollo = mkHost "apollo";
        dns1 = mkHost "dns1";
        dns2 = mkHost "dns2";
        forgejo = mkHost "forgejo";
        headscale = mkHost "headscale";
        authentik = mkHost "authentik";
        proxy = mkHost "proxy";
        rundeck = mkHost "rundeck";
        vaultwarden = mkHost "vaultwarden";
      };

      packages.${system}.rundeck-generate-resources =
        (mkPkgs system).writeShellApplication {
          name = "rundeck-generate-resources";
          runtimeInputs = with (mkPkgs system); [
            jq
            nix
            gnugrep
          ];
          text = builtins.readFile ./scripts/rundeck-generate-resources.sh;
        };

      devShells.${system}.unreal =
        let pkgs = mkPkgs system;
        in import ./shells/unreal.nix { inherit pkgs; };

      formatter.${system} = (mkPkgs system).nixpkgs-fmt;
    };
}

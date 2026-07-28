{
  description = "Scylla — reusable NixOS configurations for a fleet of mythic hosts";

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
      flatpakModule = inputs."nix-flatpak".nixosModules.nix-flatpak;

      mkPkgs =
        hostSystem:
        import nixpkgs {
          system = hostSystem;
        };

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
          specialArgs = { inherit inputs pkgsStable; };
          modules = [
            flatpakModule
            inputs.sops-nix.nixosModules.sops
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "before-home-manager";
              home-manager.extraSpecialArgs = { inherit pkgsStable; };
            }
            ./hosts/${hostname}/configuration.nix
          ];
        };

      hostDirectories = builtins.readDir ./hosts;
      hostNames = lib.filter (
        hostname:
        hostDirectories.${hostname} == "directory"
        && builtins.pathExists (./hosts + "/${hostname}/configuration.nix")
      ) (builtins.attrNames hostDirectories);
    in
    {
      nixosConfigurations = lib.genAttrs hostNames mkHost;

      packages.${system}.rundeck-generate-resources = (mkPkgs system).writeShellApplication {
        name = "rundeck-generate-resources";
        runtimeInputs = with (mkPkgs system); [
          jq
          nix
          gnugrep
        ];
        text = builtins.readFile ./scripts/rundeck-generate-resources.sh;
      };

      devShells.${system}.unreal =
        let
          pkgs = mkPkgs system;
        in
        import ./shells/unreal.nix { inherit pkgs; };

      formatter.${system} = (mkPkgs system).nixpkgs-fmt;
    };
}

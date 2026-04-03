{
  description = "Allie's systems nixos config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #lix-module = {
    #  url = "git+https://git.lix.systems/lix-project/nixos-module";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #x};
  };

  outputs = { self, nixpkgs, nur, lix-module, ... }:
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
          nur.modules.nixos.default
          lix-module.nixosModules.lixFromNixpkgs

          ./modules/common.nix
          ./modules/plasma.nix
          ./modules/browsers.nix
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  #stateVersion = "25.11"; # Did you read the comment?

}

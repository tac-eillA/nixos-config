{
  description = "Artemis NixOS config (niri shell, self-contained dotfiles)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      artemisVars = import ./hosts/artemis/variables.nix;
      system = artemisVars.host.system or "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations.artemis = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          vars = artemisVars;
        };
        modules = [
          ./hosts/artemis/configuration.nix
        ];
      };

      devShells.${system} = {
        rust = pkgs.mkShell {
          packages = [
            pkgs.rustc
            pkgs.cargo
            pkgs.rustfmt
            pkgs.clippy
            pkgs."rust-analyzer"
            pkgs.pkg-config
            pkgs.openssl
          ];

          shellHook = ''
            echo "Rust dev shell ready (cargo/rustc/rust-analyzer)"
          '';
        };

        go = pkgs.mkShell {
          packages = [
            pkgs.go
            pkgs.gopls
            pkgs.delve
          ];

          shellHook = ''
            echo "Go dev shell ready (go/gopls/delve)"
          '';
        };
      };
    };
}

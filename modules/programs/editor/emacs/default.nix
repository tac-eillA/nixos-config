{ pkgs, ... }:
{
  home-manager.sharedModules = [
    (_: {
      programs.emacs = {
        enable = true;
        package = pkgs.emacs.override {
          withGTK3 = true;
          withPgtk = true; # true on wayland
          withNativeCompilation = true;
          withTreeSitter = true;
        };
      };
      services.emacs = {
        enable = true;
        package = pkgs.emacs-unstable; # replace with emacs-gtk, or a version provided by the community overlay if desired.
      };
      nixpkgs.overlays = [
        (import (builtins.fetchTarball {
          url = "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
        }))
      ];
    })
  ];
}

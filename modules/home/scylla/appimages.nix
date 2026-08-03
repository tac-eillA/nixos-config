{ pkgs, ... }:

let
  updateAppimages = pkgs.writeShellApplication {
    name = "scylla-update-appimages";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      git
      gh
      jq
      nix
    ];
    text = builtins.readFile ../../../scripts/update-appimages;
  };
in
{
  home.packages = [ updateAppimages ];
}

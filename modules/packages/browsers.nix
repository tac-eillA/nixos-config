{ pkgs, ... }:

let
  helium = pkgs.callPackage ./helium.nix { };
in
{
  programs.firefox = {
    enable = true;

    preferences = {
      "browser.tabs.unloadOnLowMemory" = true;
      "dom.ipc.processCount" = 6;
    };
  };

  environment.systemPackages = [ helium ];
}

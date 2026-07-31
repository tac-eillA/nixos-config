{ config, lib, pkgs, ... }:

let
  t3codeDev = pkgs.writeShellApplication {
    name = "t3code-dev";
    runtimeInputs = [ pkgs.nix ];
    text = ''
      exec nix develop ${lib.escapeShellArg "${config.home.homeDirectory}/nixos-config#t3code"} \
        --command t3code "$@"
    '';
  };
in
{
  home.packages = [ t3codeDev ];

  xdg.desktopEntries.t3code-dev = {
    name = "T3 Code (Development)";
    genericName = "Coding agent GUI in the T3 Code development shell";
    exec = "t3code-dev %U";
    icon = "t3code";
    terminal = false;
    categories = [ "Development" ];
  };
}

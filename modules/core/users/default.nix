
{
  pkgs,
  inputs,
  host,
  ...
}:
let
  inherit (import ../../../hosts/${host}/variables.nix)
    username
    editor
    terminal
    browser
    shell
    ;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager
       ./allison.nix
       #./custom.nix
   ];
  programs.dconf.enable = true; # Enable dconf for home-manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    };
  nix.settings.allowed-users = [ "${username}" "allison" ];
}

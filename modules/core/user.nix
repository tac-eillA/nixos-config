{ pkgs, ... }:

{
  users.users."allison" = {
    isNormalUser = true;
    description = "allison";
    extraGroups = [ "wheel" "networkmanager" "nordvpn" "netbird" ];
    shell = pkgs.zsh;
  };
}

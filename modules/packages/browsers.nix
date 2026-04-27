{ pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    nur.repos.lonerOrz.helium
  ];
}

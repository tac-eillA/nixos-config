{ pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = [
    pkgs.nur.repos.lonerOrz.helium
  ];
}

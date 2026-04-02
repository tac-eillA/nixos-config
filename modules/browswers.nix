{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nur.repos.lonerOrz.helium
    nur.repos.natsukium.zen-browser
  ];
}

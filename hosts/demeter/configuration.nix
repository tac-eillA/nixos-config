{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
  ];

  networking.hostName = "demeter";

  systemd.services.plasmalogin.preStart = ''
    ${pkgs.coreutils}/bin/install -Dm600 \
      -o plasmalogin \
      -g plasmalogin \
      ${./kwinoutputconfig.json} \
      /var/lib/plasmalogin/.config/kwinoutputconfig.json
  '';
}

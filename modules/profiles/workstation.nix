{ ... }:

{
  imports = [
    ../../modules/system.nix
    ../../modules/boot.nix
    ../../modules/network.nix
    ../../modules/dev.nix
    ../../modules/gaming.nix
    ../../modules/peripherals.nix
    ../../modules/fonts.nix
    ../../modules/printing.nix
    ../../modules/plasma.nix
    ../../modules/services.nix
    ../..modules/shell.nix
    ../../modules/user.nix
    ../../modules/video.nix
    ../../modules/apps.nix
    ../../modules/browsers.nix
    ../../modules/flatpak.nix
  ];

}

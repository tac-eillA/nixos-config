{ pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    emacs
    neovim
    blender
    kicad
    krita
    opentabletdriver
    pciutils
    usbutils
    lspci
    lact
    btop
    calibre
    mpv
    cider-2
    wireshark
    helium-browser
    zen-browser
  ];
}

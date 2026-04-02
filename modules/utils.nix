{ pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    emacs
    neovim
    blender
    kicad
    krita
    kdenlive
    obs-studio
    vial
    qbittorrent
    foliate
    easyeffects
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
    google-chrome
  ];
}

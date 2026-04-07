{ pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    blender
    kicad
    krita
    obs-studio
    vial
    qbittorrent
    foliate
    easyeffects
    opentabletdriver
    pciutils
    usbutils
    lact
    btop
    calibre
    mpv
    cider-2
    wireshark
    google-chrome
  ];
}

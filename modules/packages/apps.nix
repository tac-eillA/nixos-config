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
    calibre
    mpv
    cider-2
    #wireshark
    google-chrome
    hyfetch
    gparted
    ffmpeg
    flatpak
    libreoffice-fresh
    streamrip
    kontainer
    moonlight-qt
  ];
}

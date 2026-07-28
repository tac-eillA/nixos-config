{ pkgs, pkgsStable, ... }:

let
  # Packages use nixos-unstable unless explicitly moved to pkgsStable.
  unstablePackages = with pkgs; [
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

  stablePackages = with pkgsStable; [
    # LACT 0.9.1 currently fails to build on unstable.
    lact
  ];
in
{
  environment.systemPackages = unstablePackages ++ stablePackages;
}

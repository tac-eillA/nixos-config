{ pkgs, pkgsStable, ... }:

let
  t3code = pkgs.callPackage ./t3code.nix { };
  t3codeNightly = pkgs.callPackage ./t3code.nix { nightly = true; };

  # Packages use nixos-unstable unless explicitly moved to pkgsStable.
  unstablePackages = with pkgs; [
    blender
    godot
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
    fastfetch
    gparted
    ffmpeg
    libreoffice-fresh
    streamrip
    kontainer
    moonlight-qt
  ];

  stablePackages = with pkgsStable; [
    wireshark
    google-chrome #needed for webserial for web based via/vial
  ];
in
{
  environment.systemPackages = unstablePackages ++ stablePackages ++ [
    t3code
    t3codeNightly
  ];
}

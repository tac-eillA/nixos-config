{ pkgs, pkgsStable, ... }:

let
  codex = pkgs.callPackage ./codex.nix { };
  opencode = pkgs.callPackage ./opencode.nix { };
  t3code = pkgs.callPackage ./t3code.nix { };

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
  environment.systemPackages = unstablePackages ++ stablePackages ++ [ codex opencode t3code ];
}

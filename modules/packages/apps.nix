{ pkgs, pkgsStable, ... }:

let
  t3code = pkgs.callPackage ./t3code.nix { };
  t3codeNightly = pkgs.callPackage ./t3code.nix { nightly = true; };

  # Packages use nixos-unstable unless explicitly moved to pkgsStable.
  unstablePackages = with pkgs; [
    vial
    opentabletdriver
    cider-2
    fastfetch
    gparted
    ffmpeg
    streamrip
    kontainer
    nordvpn
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

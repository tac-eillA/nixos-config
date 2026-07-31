{ pkgs, ... }:

{
  imports = [ ./minimal.nix ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      zstd
      openssl
      curl

      libX11
      libXcursor
      libXi
      libXinerama
      libXrandr
      libXxf86vm
      libxcb

      libxkbcommon
      wayland
      alsa-lib
      vulkan-loader
    ];
  };

  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    fzf
    fd
    ripgrep
    unzip
    p7zip
    file
    vim
    kitty
    nixd
    nil

    pciutils
    usbutils
    btop

    vulkan-tools
    mesa-demos
    pavucontrol
    mangohud
    steam-run

    emacs
    jetbrains.rider
    jetbrains.clion
    jetbrains.rust-rover
    zed-editor-fhs
    opencode
    codex
    claude-code
    python3
    detect-secrets
  ];
}

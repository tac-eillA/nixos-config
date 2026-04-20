{ pkgs, config, ... }:

{
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

  programs.steam.enable = true;
  security.rtkit.enable = true;
  programs.gamemode.enable = true;
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    lfs = {
      enable = true;
      skipSmudge = true;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    gh
    bash
    curl
    wget
    fzf
    fd
    ripgrep
    git-lfs
    unzip
    p7zip
    file
    which
    vim
    kitty
    ghostty

    pciutils
    usbutils
    lact
    btop

    vulkan-tools
    mesa-demos
    pavucontrol
    mangohud
    steam-run

    emacs
    neovim
    jetbrains.rider
    jetbrains.clion
    jetbrains.rust-rover
    zed-editor-fhs
  ];
}

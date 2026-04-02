{ pkgs, ... }:

{
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      zstd
      openssl
      curl

      xorg.libX11
      xorg.libXcursor
      xorg.libXi
      xorg.libXinerama
      xorg.libXrandr
      xorg.libXxf86vm
      xorg.libxcb

      libxkbcommon
      wayland
      alsa-lib
      vulkan-loader
    ];
  };

  programs.steam.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    git-lfs
    unzip
    p7zip
    file
    which

    vulkan-tools
    mesa-demos
    pavucontrol
    mangohud
    steam-run
  ];
}

{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nixpkgs.config.allowUnfree = true;

  networking.networkmanager.enable = true;

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_US.UTF-8";

  # Replace "youruser" with your actual username.
  users.users."allison" = {
    isNormalUser = true;
    description = "allison";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    git
    gh
    bash
    curl
    wget
    fzf
    fd
    ripgrep
    microfetch
    gparted
    ffmpeg
    vim
    kitty
    ghostty
    flatpak
    libreoffice-fresh
    brightnessctl
    fprintd
    vlc
  ];

  services.tailscale.enable = true;
  services.lact.enable = true;

}

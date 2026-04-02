{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  networking.networkmanager.enable = true;

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_US.UTF-8";

  # Replace "youruser" with your actual username.
  users.users."allison" = {
    isNormalUser = true;
    description = "allison";
    extraGroups = [ "wheel" "networkmanager" ];
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    fzf
    ffmpeg
    vim
    kitty
    firefox
    libreoffice-fresh
    brightnessctl
    fprintd
    vlc
  ];
}

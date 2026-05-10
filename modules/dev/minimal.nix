{ pkgs, ... }:

{
  imports = [ ./git.nix ];

  environment.systemPackages = with pkgs; [
    gh
    bash
    curl
    wget
    which
    ghostty
    neovim
    openssl
    libargon2
    mosh
    tmux
    tailscale
    bitwarden-cli
    bitwarden-desktop
  ];

  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };
}

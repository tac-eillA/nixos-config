{ pkgs, ... }:

{
  imports = [ ./git.nix ];

  environment.systemPackages = with pkgs; [
    gh
    bash
    curl
    wget
    which
    neovim
    openssl
    libargon2
    mosh
    tmux
    tailscale
    bitwarden-cli
  ];
}

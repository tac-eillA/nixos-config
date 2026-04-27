{ pkgs, config, ... }:

{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    lfs = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    gh
    bash
    curl
    wget
    git-lfs
    which
    ghostty
    neovim
    openssl
    argon2
  ];
}

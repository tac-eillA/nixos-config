{ ... }:

{
  imports = [
    ./git.nix
    ./ghostty.nix
    ./neovim.nix
    ./tmux.nix
    ./zsh.nix
  ];

  home = {
    username = "allison";
    homeDirectory = "/home/allison";
    stateVersion = "26.11";
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs.home-manager.enable = true;
}

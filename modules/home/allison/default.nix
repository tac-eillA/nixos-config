{ ... }:

{
  imports = [
    ./git.nix
    ./ghostty.nix
    ./zsh.nix
  ];

  home = {
    username = "allison";
    homeDirectory = "/home/allison";
    stateVersion = "26.05";
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs.home-manager.enable = true;
}

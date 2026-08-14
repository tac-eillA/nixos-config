{ osConfig, ... }:

{
  imports = [
    ./git.nix
    ./gnome.nix
    ./ghostty.nix
    ./neovim.nix
    ./appimages.nix
    ./tmux.nix
    ./zsh.nix
  ];

  home = {
    username = osConfig.scylla.user.name;
    homeDirectory = osConfig.users.users.${osConfig.scylla.user.name}.home;
    stateVersion = "26.11";
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs.home-manager.enable = true;
}

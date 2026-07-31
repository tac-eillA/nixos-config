{ osConfig, ... }:

{
  imports = [
    ./git.nix
    ./ghostty.nix
    ./neovim.nix
    ./tmux.nix
    ./t3code.nix
    ./zsh.nix
  ];

  home = {
    username = osConfig.scylla.user.name;
    homeDirectory =
      if osConfig.scylla.user.homeDirectory == null
      then "/home/${osConfig.scylla.user.name}"
      else osConfig.scylla.user.homeDirectory;
    stateVersion = "26.11";
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs.home-manager.enable = true;
}

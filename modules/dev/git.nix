{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    lfs.enable = true;

    config = {
      init.defaultBranch = "main";
      user = {
        name = "Allison Snodgrass";
        email = "email@allie.is";
      };
    };
  };
}

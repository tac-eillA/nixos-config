{
  pkgs,
  config,
  ...
}:

{
  home-manager.sharedModules = [
    (_: {

  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    lfs = {
      enable = true;
      skipSmudge = true;
    };
  };
    })
  ];
}

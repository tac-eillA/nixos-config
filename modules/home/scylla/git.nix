{ lib, osConfig, pkgs, ... }:

{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    lfs.enable = true;
    settings = {
      init.defaultBranch = "main";
      user =
        lib.optionalAttrs (osConfig.scylla.user.git.name != null)
          {
            name = osConfig.scylla.user.git.name;
          }
        // lib.optionalAttrs (osConfig.scylla.user.git.email != null) {
          email = osConfig.scylla.user.git.email;
        };
    };
  };
}

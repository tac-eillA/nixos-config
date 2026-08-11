{ lib, osConfig, pkgs, ... }:

{
  programs.gh = {
    enable = true;
    settings.git_protocol = "https";
  };

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

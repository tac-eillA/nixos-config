{ pkgs, vars, ... }:
let
  repoRoot = (vars.paths or { }).repoRoot or "/etc/nixos";
in
{
  environment.sessionVariables.NIXOS_CONFIG_REPO = repoRoot;

  systemd.user.services.link-configs = {
    description = "Symlink shell config from the repo config directory";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash ${repoRoot}/scripts/link-configs.sh";
      Environment = [ "NIXOS_CONFIG_REPO=${repoRoot}" ];
    };
  };
}

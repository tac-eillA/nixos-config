{ config, ... }:

let
  username = config.scylla.user.name;
  homeDirectory =
    if config.scylla.user.homeDirectory == null
    then "/home/${username}"
    else config.scylla.user.homeDirectory;
in
{
  imports = [ ./runtime-age.nix ];

  sops.secrets."gh/hosts-yml" = {
    sopsFile = ../../secrets/github.yaml;
    path = "${homeDirectory}/.config/gh/hosts.yml";
    owner = username;
    group = "users";
    mode = "0600";
  };

  systemd.tmpfiles.rules = [
    "d ${homeDirectory}/.config 0700 ${username} users - -"
    "d ${homeDirectory}/.config/gh 0700 ${username} users - -"
  ];
}

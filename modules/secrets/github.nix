{ config, ... }:

let
  username = config.scylla.user.name;
  homeDirectory = config.users.users.${username}.home;
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

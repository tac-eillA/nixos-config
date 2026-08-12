{ config, ... }:

let
  username = config.scylla.user.name;
  homeDirectory = config.users.users.${username}.home;
in
{
  imports = [ ./runtime-age.nix ];

  # Keep the OAuth token in this SOPS-encrypted hosts.yml payload. Headless
  # workstation services can start before an autologin session has supplied a
  # password to GNOME Keyring, but gh's Git credential helper must still remain
  # non-interactive after a reboot.
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

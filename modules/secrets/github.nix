{ ... }:

{
  imports = [ ./runtime-age.nix ];

  sops.secrets."gh/hosts-yml" = {
    sopsFile = ../../secrets/github.yaml;
    path = "/home/allison/.config/gh/hosts.yml";
    owner = "allison";
    group = "users";
    mode = "0600";
  };

  systemd.tmpfiles.rules = [
    "d /home/allison/.config 0700 allison users - -"
    "d /home/allison/.config/gh 0700 allison users - -"
  ];
}

{ config, lib, ... }:

let
  cfg = config.scylla.roles.technitium-dns;
in
{
  options.scylla.roles.technitium-dns = {
    enable = lib.mkEnableOption "the Technitium DNS workload";
  };

  config = lib.mkIf cfg.enable {
    services.technitium-dns-server = {
      enable = true;
      openFirewall = false;
    };
  };
}

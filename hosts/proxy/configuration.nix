{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
  ];

  networking.hostName = "proxy";

  # VPS mock: regenerate hardware-configuration.nix for the actual provider
  # before deploying this host.
  # This VPS and every upstream must be joined to the same Tailscale tailnet.
  # The upstream names below are resolved through Tailscale MagicDNS.
  # Every ingress key is a public HTTPS endpoint; remove administrative routes
  # or add an authentication layer before deployment if they should stay private.
  scylla.roles.proxy = {
    enable = true;
    installAdminPackages = true;
    ingress = {
      "auth.allie.sh" = "http://authentik:9000";
      "dns1-dash.allie.sh" = "http://dns1:5380";
      "dns2-dash.allie.sh" = "http://dns2:5380";
      "git.allie.sh" = "http://forgejo:3000";
      "vault.allie.sh" = "http://vaultwarden:8222";
    };
  };

  scylla.network.exposures = [
    {
      name = "caddy-http";
      port = 80;
      protocols = [ "tcp" ];
      sources = [ ];
    }
    {
      name = "caddy-https";
      port = 443;
      protocols = [
        "tcp"
        "udp"
      ];
      sources = [ ];
    }
  ];
}

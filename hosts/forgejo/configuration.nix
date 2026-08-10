{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
  ];

  networking.hostName = "forgejo";
  systemd.network.networks."10-uplink".address = [ "10.254.1.213/24" ];

  scylla.roles.forgejo = {
    enable = true;
    domain = "git.allie.sh";
    listenAddress = "10.254.1.213";
    port = 3000;
    oidcDiscoveryUrl =
      "https://auth.allie.sh/application/o/forgejo/.well-known/openid-configuration";
    installAdminPackages = true;
  };

  scylla.network.exposures = [
    {
      name = "forgejo";
      port = 3000;
      protocols = [ "tcp" ];
      sources = [ "10.254.1.215/32" ];
    }
  ];
}

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/server.nix
  ];

  networking.hostName = "vaultwarden";
  systemd.network.networks."10-uplink".address = [ "10.254.1.216/24" ];

  scylla.roles.vaultwarden = {
    enable = true;
    domain = "vault.allie.sh";
    listenAddress = "10.254.1.216";
    port = 8222;
    oidcIssuer = "https://auth.allie.sh/application/o/vaultwarden/";
  };

  scylla.network.exposures = [
    {
      name = "vaultwarden";
      port = 8222;
      protocols = [ "tcp" ];
      sources = [ "10.254.1.215/32" ];
    }
  ];
}

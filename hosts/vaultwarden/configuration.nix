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
    listenAddress = "0.0.0.0";
    port = 8222;
    oidcIssuer = "https://auth.allie.sh/application/o/vaultwarden/";
  };

  scylla.network.exposures = [
    {
      name = "vaultwarden";
      port = 8222;
      protocols = [ "tcp" ];
      sources = [ "100.64.0.0/10" ];
    }
  ];
}

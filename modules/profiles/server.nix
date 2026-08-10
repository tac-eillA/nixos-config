{ inputs, lib, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops

    ../core
    ../features/development/minimal.nix
    ../features/tailscale.nix
    ../networking/exposure.nix
    ../roles/authentik
    ../roles/forgejo
    ../roles/headscale
    ../roles/paperless-ngx
    ../roles/proxy
    ../roles/technitium-dns
    ../roles/vaultwarden
  ];

  networking = {
    networkmanager.enable = lib.mkForce false;
    useDHCP = lib.mkForce false;
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;

    networks."10-uplink" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
    };
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
  };
  services.qemuGuest.enable = true;

  scylla.network.exposures = lib.mkAfter [
    {
      name = "openssh-lan-only";
      port = 22;
      protocols = [ "tcp" ];
      sources = [ "10.254.1.0/24" ];
    }
    {
      name = "openssh-tailscale-only";
      port = 22;
      protocols = [ "tcp" ];
      sources = [ "100.64.0.0/10" ];
    }
  ];
}

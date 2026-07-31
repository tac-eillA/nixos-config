let
  networks = import ./networks.nix;

  addresses = {
    authentik = "10.254.1.210";
    dns1 = "10.254.1.211";
    dns2 = "10.254.1.212";
    forgejo = "10.254.1.213";
    headscale = "10.254.1.214";
    proxy = "10.254.1.215";
    vaultwarden = "10.254.1.216";
  };

  baseFeatures = [
    "audio"
    "firmware"
    "tailscale"
  ];

  serverFeatures = baseFeatures ++ [ "development-minimal" ];

  serverAdministration = {
    ssh = {
      port = 22;
      exposures = [
        {
          classification = "lan-only";
          trustedNetworks = networks.lan;
        }
        {
          classification = "tailscale-only";
          trustedNetworks = networks.tailscale;
        }
      ];
    };
  };

  workstationFeatures = baseFeatures ++ [
    "desktop"
    "development-full"
    "distrobox"
    "gaming"
    "github-secret"
    "printing"
  ];
in
{
  artemis = {
    system = "x86_64-linux";
    profile = "workstation";
    deployable = false;
    address = null;
    features = workstationFeatures;
    roles = [ ];
  };

  athena = {
    system = "x86_64-linux";
    profile = "workstation";
    deployable = true;
    address = null;
    hardwareModules = [ "framework-amd-ai-300-series" ];
    features = workstationFeatures;
    roles = [ ];
  };

  authentik = {
    system = "x86_64-linux";
    profile = "server";
    deployable = true;
    address = addresses.authentik;
    features = serverFeatures;
    administration = serverAdministration;
    roles = [ "authentik" ];
    roleSettings.authentik = {
      installAdminPackages = true;
    };
  };

  demeter = {
    system = "x86_64-linux";
    profile = "workstation";
    deployable = true;
    address = null;
    features = workstationFeatures;
    roles = [ ];
  };

  dns1 = {
    system = "x86_64-linux";
    profile = "server";
    deployable = true;
    address = addresses.dns1;
    features = serverFeatures;
    administration = serverAdministration;
    roles = [ "technitium-dns" ];
  };

  dns2 = {
    system = "x86_64-linux";
    profile = "server";
    deployable = true;
    address = addresses.dns2;
    features = serverFeatures;
    administration = serverAdministration;
    roles = [ "technitium-dns" ];
  };

  forgejo = {
    system = "x86_64-linux";
    profile = "server";
    deployable = true;
    address = addresses.forgejo;
    features = serverFeatures;
    administration = serverAdministration;
    roles = [ "forgejo" ];
    roleSettings.forgejo = {
      oidcDiscoveryUrl =
        "https://auth.allie.sh/application/o/forgejo/.well-known/openid-configuration";
      installAdminPackages = true;
    };
  };

  headscale = {
    system = "x86_64-linux";
    profile = "server";
    deployable = true;
    address = addresses.headscale;
    features = serverFeatures;
    administration = serverAdministration;
    roles = [ "headscale" ];
    roleSettings.headscale = {
      oidcIssuer = "https://auth.allie.sh/application/o/headscale/";
      installAdminPackages = true;
    };
  };

  hera = {
    system = "x86_64-linux";
    profile = "base";
    deployable = false;
    address = null;
    features = baseFeatures;
    roles = [ ];
  };

  proxy = {
    system = "x86_64-linux";
    profile = "server";
    deployable = true;
    address = addresses.proxy;
    features = serverFeatures;
    administration = serverAdministration;
    roles = [ "proxy" ];
    roleSettings.proxy = {
      installAdminPackages = true;
    };
  };

  pythia = {
    system = "x86_64-linux";
    profile = "base";
    deployable = false;
    address = null;
    features = baseFeatures;
    roles = [ ];
  };

  vaultwarden = {
    system = "x86_64-linux";
    profile = "server";
    deployable = true;
    address = addresses.vaultwarden;
    features = serverFeatures;
    administration = serverAdministration;
    roles = [ "vaultwarden" ];
    roleSettings.vaultwarden = {
      oidcIssuer = "https://auth.allie.sh/application/o/vaultwarden/";
    };
  };
}

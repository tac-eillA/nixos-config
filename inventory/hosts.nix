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

  serverFeatures = [
    "development-minimal"
    "tailscale"
  ];

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

  workstationFeatures = [
    "appimage"
    "audio"
    "desktop"
    "development-full"
    "distrobox"
    "firmware"
    "gaming"
    "github-secret"
    "printing"
    "tailscale"
    "tailscale-operator"
  ];

  mkHost = profile: features: overrides: {
    system = "x86_64-linux";
    inherit profile features;
    deployable = true;
    address = null;
    roles = [ ];
  } // overrides;

  mkWorkstation = mkHost "workstation" workstationFeatures;

  mkServer = hostname: role: overrides:
    mkHost "server" serverFeatures ({
      address = addresses.${hostname};
      administration = serverAdministration;
      roles = [ role ];
    } // overrides);

  placeholderHost = mkHost "base" [ ] {
    deployable = false;
  };
in
{
  artemis = mkWorkstation {
    deployable = false;
  };

  athena = mkWorkstation {
    hardwareModules = [ "framework-amd-ai-300-series" ];
  };

  authentik = mkServer "authentik" "authentik" {
    roleSettings.authentik = {
      installAdminPackages = true;
    };
  };

  demeter = mkWorkstation { };

  dns1 = mkServer "dns1" "technitium-dns" { };

  dns2 = mkServer "dns2" "technitium-dns" { };

  forgejo = mkServer "forgejo" "forgejo" {
    roleSettings.forgejo = {
      oidcDiscoveryUrl =
        "https://auth.allie.sh/application/o/forgejo/.well-known/openid-configuration";
      installAdminPackages = true;
    };
  };

  headscale = mkServer "headscale" "headscale" {
    roleSettings.headscale = {
      oidcIssuer = "https://auth.allie.sh/application/o/headscale/";
      installAdminPackages = true;
    };
  };

  hera = placeholderHost;

  proxy = mkServer "proxy" "proxy" {
    roleSettings.proxy = {
      installAdminPackages = true;
    };
  };

  pythia = placeholderHost;

  vaultwarden = mkServer "vaultwarden" "vaultwarden" {
    roleSettings.vaultwarden = {
      oidcIssuer = "https://auth.allie.sh/application/o/vaultwarden/";
    };
  };
}

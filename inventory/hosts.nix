let
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
    roles = [ "authentik" ];
    roleSettings.authentik = {
      domain = "auth.allie.sh";
      listenAddress = "0.0.0.0";
      port = 9000;
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
    roles = [ "technitium-dns" ];
  };

  dns2 = {
    system = "x86_64-linux";
    profile = "server";
    deployable = true;
    address = addresses.dns2;
    features = serverFeatures;
    roles = [ "technitium-dns" ];
  };

  forgejo = {
    system = "x86_64-linux";
    profile = "server";
    deployable = true;
    address = addresses.forgejo;
    features = serverFeatures;
    roles = [ "forgejo" ];
    roleSettings.forgejo = {
      domain = "git.allie.sh";
      listenAddress = "0.0.0.0";
      port = 3000;
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
    roles = [ "headscale" ];
    roleSettings.headscale = {
      domain = "headscale.allie.sh";
      listenAddress = "0.0.0.0";
      port = 80;
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
    roles = [ "proxy" ];
    roleSettings.proxy = {
      installAdminPackages = true;
      ingress = {
        "git.allie.sh" = "http://${addresses.forgejo}:3000";
        "headscale.allie.sh" = "http://${addresses.headscale}:80";
        "auth.allie.sh" = "http://${addresses.authentik}:9000";
        "vault.allie.sh" = "http://${addresses.vaultwarden}:8222";
        "dns1-dash.allie.sh" = "http://${addresses.dns1}:5380";
        "dns2-dash.allie.sh" = "http://${addresses.dns2}:5380";
        "dns1.allie.sh" = "http://${addresses.dns1}:53";
        "dns2.allie.sh" = "http://${addresses.dns2}:53";
      };
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
    roles = [ "vaultwarden" ];
    roleSettings.vaultwarden = {
      domain = "vault.allie.sh";
      listenAddress = "0.0.0.0";
      port = 8222;
      oidcIssuer = "https://auth.allie.sh/application/o/vaultwarden/";
    };
  };
}

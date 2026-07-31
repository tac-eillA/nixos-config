{ hosts, networks }:

let
  cloudflarePublication = domain: {
    via = "cloudflare";
    inherit domain;
  };

  proxyOnly = {
    classification = "proxy-only";
    trustedHosts = [ "proxy" ];
    trustedNetworks = [ ];
    consumedByProxy = true;
  };

  unpublished = {
    via = "none";
    domain = null;
  };
in
{
  authentik = {
    host = "authentik";
    role = "authentik";
    listener = {
      address = hosts.authentik.address;
      domain = "auth.allie.sh";
      port = 9000;
      protocols = [ "tcp" ];
      scheme = "http";
    };
    exposure = proxyOnly;
    publication = cloudflarePublication "auth.allie.sh";
  };

  dns1 = {
    host = "dns1";
    role = "technitium-dns";
    listener = {
      address = "0.0.0.0";
      domain = null;
      port = 53;
      protocols = [
        "tcp"
        "udp"
      ];
      scheme = "dns";
    };
    exposure = {
      classification = "lan-only";
      trustedHosts = [ ];
      trustedNetworks = networks.lan;
      consumedByProxy = false;
    };
    publication = unpublished;
  };

  dns1-dashboard = {
    host = "dns1";
    role = "technitium-dns";
    listener = {
      address = "0.0.0.0";
      domain = "dns1-dash.allie.sh";
      port = 5380;
      protocols = [ "tcp" ];
      scheme = "http";
    };
    exposure = proxyOnly;
    publication = cloudflarePublication "dns1-dash.allie.sh";
  };

  dns2 = {
    host = "dns2";
    role = "technitium-dns";
    listener = {
      address = "0.0.0.0";
      domain = null;
      port = 53;
      protocols = [
        "tcp"
        "udp"
      ];
      scheme = "dns";
    };
    exposure = {
      classification = "lan-only";
      trustedHosts = [ ];
      trustedNetworks = networks.lan;
      consumedByProxy = false;
    };
    publication = unpublished;
  };

  dns2-dashboard = {
    host = "dns2";
    role = "technitium-dns";
    listener = {
      address = "0.0.0.0";
      domain = "dns2-dash.allie.sh";
      port = 5380;
      protocols = [ "tcp" ];
      scheme = "http";
    };
    exposure = proxyOnly;
    publication = cloudflarePublication "dns2-dash.allie.sh";
  };

  forgejo = {
    host = "forgejo";
    role = "forgejo";
    listener = {
      address = hosts.forgejo.address;
      domain = "git.allie.sh";
      port = 3000;
      protocols = [ "tcp" ];
      scheme = "http";
    };
    exposure = proxyOnly;
    publication = cloudflarePublication "git.allie.sh";
  };

  headscale = {
    host = "headscale";
    role = "headscale";
    listener = {
      address = hosts.headscale.address;
      domain = "headscale.allie.sh";
      port = 80;
      protocols = [ "tcp" ];
      scheme = "http";
    };
    exposure = proxyOnly;
    publication = cloudflarePublication "headscale.allie.sh";
  };

  vaultwarden = {
    host = "vaultwarden";
    role = "vaultwarden";
    listener = {
      address = hosts.vaultwarden.address;
      domain = "vault.allie.sh";
      port = 8222;
      protocols = [ "tcp" ];
      scheme = "http";
    };
    exposure = proxyOnly;
    publication = cloudflarePublication "vault.allie.sh";
  };
}

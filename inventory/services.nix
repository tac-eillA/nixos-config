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

  mkProxyService =
    { host
    , role ? host
    , domain
    , port
    , address ? hosts.${host}.address
    ,
    }:
    {
      inherit host role;
      listener = {
        inherit address domain port;
        protocols = [ "tcp" ];
        scheme = "http";
      };
      exposure = proxyOnly;
      publication = cloudflarePublication domain;
    };

  mkDnsService = host: {
    inherit host;
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
in
{
  authentik = mkProxyService {
    host = "authentik";
    domain = "auth.allie.sh";
    port = 9000;
  };

  dns1 = mkDnsService "dns1";

  dns1-dashboard = mkProxyService {
    host = "dns1";
    role = "technitium-dns";
    address = "0.0.0.0";
    domain = "dns1-dash.allie.sh";
    port = 5380;
  };

  dns2 = mkDnsService "dns2";

  dns2-dashboard = mkProxyService {
    host = "dns2";
    role = "technitium-dns";
    address = "0.0.0.0";
    domain = "dns2-dash.allie.sh";
    port = 5380;
  };

  forgejo = mkProxyService {
    host = "forgejo";
    domain = "git.allie.sh";
    port = 3000;
  };

  headscale = mkProxyService {
    host = "headscale";
    domain = "headscale.allie.sh";
    port = 80;
  };

  vaultwarden = mkProxyService {
    host = "vaultwarden";
    domain = "vault.allie.sh";
    port = 8222;
  };
}

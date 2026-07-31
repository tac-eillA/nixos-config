{
  authentik = {
    host = "authentik";
    role = "authentik";
    publicDomain = "auth.allie.sh";
    scheme = "http";
    port = 9000;
    publishVia = "cloudflare";
    exposure = "public";
  };

  dns1 = {
    host = "dns1";
    role = "technitium-dns";
    publicDomain = null;
    scheme = "dns";
    port = 53;
    publishVia = "none";
    exposure = "lan";
  };

  dns1-dashboard = {
    host = "dns1";
    role = "technitium-dns";
    publicDomain = "dns1-dash.allie.sh";
    scheme = "http";
    port = 5380;
    publishVia = "cloudflare";
    exposure = "public";
  };

  dns2 = {
    host = "dns2";
    role = "technitium-dns";
    publicDomain = null;
    scheme = "dns";
    port = 53;
    publishVia = "none";
    exposure = "lan";
  };

  dns2-dashboard = {
    host = "dns2";
    role = "technitium-dns";
    publicDomain = "dns2-dash.allie.sh";
    scheme = "http";
    port = 5380;
    publishVia = "cloudflare";
    exposure = "public";
  };

  forgejo = {
    host = "forgejo";
    role = "forgejo";
    publicDomain = "git.allie.sh";
    scheme = "http";
    port = 3000;
    publishVia = "cloudflare";
    exposure = "public";
  };

  headscale = {
    host = "headscale";
    role = "headscale";
    publicDomain = "headscale.allie.sh";
    scheme = "http";
    port = 80;
    publishVia = "cloudflare";
    exposure = "public";
  };

  vaultwarden = {
    host = "vaultwarden";
    role = "vaultwarden";
    publicDomain = "vault.allie.sh";
    scheme = "http";
    port = 8222;
    publishVia = "cloudflare";
    exposure = "public";
  };
}

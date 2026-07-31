{
  authentik = {
    host = "authentik";
    role = "authentik";
    publicDomain = "auth.allie.sh";
    scheme = "http";
    port = 9000;
    publishVia = "cloudflare";
  };

  dns1 = {
    host = "dns1";
    role = "technitium-dns";
    publicDomain = "dns1.allie.sh";
    scheme = "http";
    port = 53;
    publishVia = "cloudflare";
  };

  dns1-dashboard = {
    host = "dns1";
    role = "technitium-dns";
    publicDomain = "dns1-dash.allie.sh";
    scheme = "http";
    port = 5380;
    publishVia = "cloudflare";
  };

  dns2 = {
    host = "dns2";
    role = "technitium-dns";
    publicDomain = "dns2.allie.sh";
    scheme = "http";
    port = 53;
    publishVia = "cloudflare";
  };

  dns2-dashboard = {
    host = "dns2";
    role = "technitium-dns";
    publicDomain = "dns2-dash.allie.sh";
    scheme = "http";
    port = 5380;
    publishVia = "cloudflare";
  };

  forgejo = {
    host = "forgejo";
    role = "forgejo";
    publicDomain = "git.allie.sh";
    scheme = "http";
    port = 3000;
    publishVia = "cloudflare";
  };

  headscale = {
    host = "headscale";
    role = "headscale";
    publicDomain = "headscale.allie.sh";
    scheme = "http";
    port = 80;
    publishVia = "cloudflare";
  };

  vaultwarden = {
    host = "vaultwarden";
    role = "vaultwarden";
    publicDomain = "vault.allie.sh";
    scheme = "http";
    port = 8222;
    publishVia = "cloudflare";
  };
}

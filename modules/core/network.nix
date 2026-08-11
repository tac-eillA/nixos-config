{ ... }:

{
  networking.networkmanager = {
    enable = true;
    # Let systemd-resolved arbitrate per-link DNS. This keeps the LAN resolver
    # as the default route while allowing Tailscale to install split-DNS routes
    # for MagicDNS without replacing /etc/resolv.conf through openresolv.
    dns = "systemd-resolved";
  };

  services.resolved.enable = true;

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_US.UTF-8";
}

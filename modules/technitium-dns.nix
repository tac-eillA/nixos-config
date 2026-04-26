{ ... }:

{
  services.openssh.enable = true;
  services.qemuGuest.enable = true;
  services.technitium-dns-server = {
    enable = true;
    openFirewall = true;
  };
}

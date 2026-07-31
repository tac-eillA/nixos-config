{ lib, ... }:

{
  imports = [ ./base.nix ];

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
}

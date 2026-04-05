# modules/printing.nix
{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.ipp-usb.enable = true;

  hardware.sane.enable = true;

  environment.systemPackages = with pkgs; [
    system-config-printer
    simple-scan
  ];
}

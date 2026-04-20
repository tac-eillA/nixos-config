{ pkgs, ... }:

{

  #hardware.magic-trackpad-quirks.enable = true;

  # fingerprint & login
  security.polkit.enable = true;

  logitech.wireless.enable = false;
  logitech.wireless.enableGraphical = false;
  keyboard.qmk.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    fprintd
    fwupd
    librepods
  ];

}

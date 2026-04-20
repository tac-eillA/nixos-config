{ pkgs, ... }:

{

  #hardware.magic-trackpad-quirks.enable = true;

  # fingerprint & login
  security.polkit.enable = true;

  hardware.logitech.wireless.enable = false;
  hardware.logitech.wireless.enableGraphical = false;
  hardware.keyboard.qmk.enable = true;

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

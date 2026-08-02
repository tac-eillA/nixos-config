{ pkgs, ... }:

{
  security.polkit.enable = true;
  services.fprintd.enable = true;
  services.upower.enable = true;

  # External monitor brightness uses DDC/CI over the GPU's I2C devices.
  # hardware.i2c also installs udev rules granting the logged-in local user
  # access to /dev/i2c-* without requiring the desktop shell to run as root.
  hardware.i2c.enable = true;

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
    ddcutil
    fprintd
    fwupd
    librepods
  ];
}

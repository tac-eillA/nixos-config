{ ... }:

{
  networking.firewall.enable = true;

  services = {
    fwupd.enable = true;
    lact.enable = true;
    netbird.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}

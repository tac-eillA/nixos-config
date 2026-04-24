{ ... }:

{
  # Services... self explanatory
  services.lact.enable = true;
  services.netbird.enable = true;
  #services.nordvpn.enable = true;

  # firewall
  networking.firewall.enable = true;

  services.fwupd.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

}

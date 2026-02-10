{ ... }:
{
  services.printing.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  security.polkit.enable = true;
  programs.dconf.enable = true;

  services.fwupd.enable = true;
  services.fprintd.enable = true;
  services.tailscale.enable = true;

  virtualisation.docker.enable = true;

  services.timesyncd.enable = true;
}

{ config, ... }:

{
  networking.firewall.enable = true;

  services = {
    fwupd.enable = true;
    tailscale = {
      enable = true;
      # Let the primary desktop user control Tailscale without sudo. This is
      # used by the Quickshell top-bar applet.
      extraSetFlags = [ "--operator=${config.scylla.user.name}" ];
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}

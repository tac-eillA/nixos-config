{ config, ... }:

{
  services.tailscale = {
    enable = true;

    # Let the primary desktop user control Tailscale without sudo. This is
    # used by the Quickshell top-bar applet.
    extraSetFlags = [ "--operator=${config.scylla.user.name}" ];
  };
}

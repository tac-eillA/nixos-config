{ config, ... }:

{
  # Let the primary desktop user control Tailscale without sudo. This is used
  # by the desktop status applet.
  services.tailscale.extraSetFlags = [
    "--operator=${config.scylla.user.name}"
  ];
}

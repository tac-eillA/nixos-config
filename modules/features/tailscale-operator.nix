{ config, ... }:

{
  # Let the primary desktop user control Tailscale without sudo. This is used
  # by the Quickshell top-bar applet.
  services.tailscale.extraSetFlags = [
    "--operator=${config.scylla.user.name}"
  ];
}

{ ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Add the new host to inventory/hosts.nix to select its profile, features,
  # roles, architecture, address, and deployability.
}

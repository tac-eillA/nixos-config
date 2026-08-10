{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
  ];

  # Use server.nix for a server.
  networking.hostName = "replace-me";
}

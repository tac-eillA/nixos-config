{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/base.nix
  ];

  # The shared default must not depend on repository-owned SOPS keys or
  # encrypted secrets. Add a server or workstation profile only after
  # configuring secrets for the new host.
  management.rundeckManaged.enable = false;

  networking.hostName = "default";
}

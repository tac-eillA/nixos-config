{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/base.nix
  ];

  # The shared default must not depend on repository-owned SOPS keys or
  # encrypted secrets. Add a workstation profile or secret-consuming role only
  # after configuring secrets for the new host.
  networking.hostName = "default";
}

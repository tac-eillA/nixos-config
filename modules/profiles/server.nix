{ ... }:

{
  imports = [
    ./base.nix
    ../dev/minimal.nix
  ];

  services.openssh.enable = true;
  services.qemuGuest.enable = true;
}

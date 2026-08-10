{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Ryzen AI 300 firmware does not describe every device dependency needed
  # during a system-wide power transition. Serializing device suspend/resume
  # avoids intermittent input/USB/GPU resume hangs on this platform.
  boot.kernelParams = [ "pm_async=off" ];

  # The Framework 13 has an AMD Strix integrated GPU.
  scylla.desktop.video.gpu = "amd";

{ ... }:

{
  imports = [
    ../profiles/base.nix
    ../desktop
    ../packages
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
  };
}

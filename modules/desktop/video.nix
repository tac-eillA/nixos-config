{ config, lib, pkgs, pkgsStable, ... }:

let
  cfg = config.scylla.desktop.video;
in
{
  options.scylla.desktop.video.gpu = lib.mkOption {
    type = lib.types.enum [ "generic" "amd" "nvidia" ];
    default = "generic";
    description = "GPU driver configuration for this host.";
  };

  config = {
    services.lact = {
      enable = true;
      package = pkgsStable.lact;
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = lib.optionals (cfg.gpu == "nvidia") (with pkgs; [
        nvidia-vaapi-driver
        egl-wayland
      ]);
    };

    services.xserver.videoDrivers =
      lib.optional (cfg.gpu == "nvidia") "nvidia"
      ++ lib.optional (cfg.gpu == "amd") "amdgpu";

    hardware.nvidia = lib.mkIf (cfg.gpu == "nvidia") {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
  };
}

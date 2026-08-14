{ config, inputs, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ../../modules/profiles/workstation.nix
  ];

  networking.hostName = "athena";

  # Ryzen AI 300 firmware does not describe every device dependency needed
  # during a system-wide power transition. Serializing device suspend/resume
  # avoids intermittent input/USB/GPU resume hangs on this platform.
  boot.kernelParams = [ "pm_async=off" ];

  # The Framework 13 has an AMD Strix integrated GPU.
  scylla.desktop.video.gpu = "amd";

  home-manager.users.${config.scylla.user.name} = { lib, ... }: {
      # Moonlight defaults system-key capture to off, which leaves Super/Alt
      # shortcuts with Athena's compositor instead of forwarding them to Pythia.
      # Update only this preference because the rest of this file contains
      # mutable host-pairing state and private client credentials.
      home.activation.enableMoonlightShortcutPassthrough =
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          moonlight_config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/Moonlight Game Streaming Project"
          moonlight_config="$moonlight_config_dir/Moonlight.conf"

          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$moonlight_config_dir"
          $DRY_RUN_CMD ${pkgs.crudini}/bin/crudini \
            --set "$moonlight_config" General capturesyskeys 2
        '';
    };
}

{ lib, pkgs, ... }:

let
  username = "allison";

  unrealDevAliases = pkgs.writeText "unreal-dev-aliases.sh" ''
    alias cproj='cd /workspace/projects'

    ue-start() {
      local pulse_runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      export VK_ICD_FILENAMES=/run/host/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json
      export LD_LIBRARY_PATH="/run/host/run/opengl-driver/lib:''${LD_LIBRARY_PATH:-}"
      export SDL_AUDIODRIVER=pulseaudio
      export PULSE_SERVER="unix:''${pulse_runtime}/pulse/native"

      cd /workspace/projects/UE-5.7.4/Engine/Binaries/Linux || return
      ./UnrealEditor "$@"
    }
  '';

  distroboxIniText = ''
    [unreal-dev]
    pull=true
    image=quay.io/fedora/fedora-toolbox:43
    init=false
    root=false
    replace=false
    start_now=false
    nvidia=true
    additional_packages="alsa-lib alsa-plugins-pulseaudio pipewire-libs pulseaudio-libs pango libxkbcommon libgbm libXrandr libXdamage libXcomposite-devel at-spi2-atk libxml2-devel nss.x86_64 vulkan-tools"

    home=/home/${username}/.local/share/distrobox/homes/unreal-dev

    volume="/home/${username}/Projects:/workspace/projects"
    volume="${unrealDevAliases}:/opt/distrobox-aliases/aliases.sh:ro"

    init_hooks="grep -qxF 'source /opt/distrobox-aliases/aliases.sh' ~/.bashrc || echo 'source /opt/distrobox-aliases/aliases.sh' >> ~/.bashrc"
    init_hooks="grep -qxF 'source /opt/distrobox-aliases/aliases.sh' ~/.zshrc || echo 'source /opt/distrobox-aliases/aliases.sh' >> ~/.zshrc"
  '';

  distroboxIniFile = pkgs.writeText "distrobox.ini" distroboxIniText;

  distroboxAssemblePath = lib.makeBinPath [
    pkgs.distrobox
    pkgs.podman
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
  ];
in
{
  virtualisation = {
    oci-containers.backend = "podman";

    podman = {
      enable = true;
      dockerCompat = true;

      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    distrobox
    podman
    podman-compose
    passt
    podman-tui
  ];

  systemd.user.services.distrobox-assemble = {
    description = "Create declared Distrobox containers";
    environment.PATH = lib.mkForce "/run/wrappers/bin:${distroboxAssemblePath}";

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.distrobox}/bin/distrobox-assemble create --file ${distroboxIniFile}";
    };
  };

  systemd.user.timers.distrobox-assemble = {
    description = "Create declared Distrobox containers after login";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnStartupSec = "30s";
      Unit = "distrobox-assemble.service";
    };
  };

  services.flatpak.packages = [
    "io.github.dvlv.boxbuddyrs"
  ];

  environment.etc."distrobox/distrobox.ini".text = distroboxIniText;
}

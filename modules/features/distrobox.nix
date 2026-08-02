{ config, lib, pkgs, ... }:

let
  username = config.scylla.user.name;
  homeDirectory = config.users.users.${username}.home;

  hostBrowserWrappers = pkgs.runCommand "distrobox-host-browser-wrappers" { } ''
        mkdir -p "$out/bin"

        for name in xdg-open sensible-browser x-www-browser; do
          cat > "$out/bin/$name" <<'EOF'
    #!/bin/sh
    exec distrobox-host-exec xdg-open "$@"
    EOF
          chmod +x "$out/bin/$name"
        done

        for name in firefox firefox-esr; do
          cat > "$out/bin/$name" <<'EOF'
    #!/bin/sh
    exec distrobox-host-exec firefox "$@"
    EOF
          chmod +x "$out/bin/$name"
        done

        for name in helium google-chrome google-chrome-stable; do
          cat > "$out/bin/$name" <<'EOF'
    #!/bin/sh
    exec distrobox-host-exec xdg-open "$@"
    EOF
          chmod +x "$out/bin/$name"
        done
  '';

  unrealDevAliases = pkgs.writeText "unreal-dev-aliases.sh" ''
    case ":''${PATH}:" in
      *":/opt/distrobox-browser/bin:"*) ;;
      *) export PATH="/opt/distrobox-browser/bin:''${PATH}" ;;
    esac

    export BROWSER="''${BROWSER:-firefox}"

    alias cproj='cd /workspace/projects'

    _ue_pid_file() {
      printf '%s\n' "''${UNREAL_EDITOR_PID_FILE:-/tmp/unreal-editor.pid}"
    }

    _ue_pid_alive() {
      [ -n "''${1:-}" ] && kill -0 "$1" 2>/dev/null
    }

    _ue_related_pids() {
      ps -u "$(id -u)" -o pid=,args= 2>/dev/null | awk -v root="/workspace/projects/UE-5.7.4/Engine" '
        index($0, root) && $0 ~ /(UnrealEditor|ShaderCompileWorker|CrashReportClient)/ {
          print $1
        }
      '
    }

    _ue_wait_for_exit() {
      local pid="$1"
      local count=0

      while _ue_pid_alive "$pid" && [ "$count" -lt 20 ]; do
        sleep 0.25
        count=$((count + 1))
      done
    }

    ue-stop() {
      local pid_file="$(_ue_pid_file)"
      local pid=""

      if [ -f "$pid_file" ]; then
        pid="$(cat "$pid_file" 2>/dev/null || true)"
      fi

      if _ue_pid_alive "$pid"; then
        kill -TERM "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
        _ue_wait_for_exit "$pid"

        if _ue_pid_alive "$pid"; then
          kill -KILL "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
        fi
      fi

      local related_pid
      for related_pid in $(_ue_related_pids); do
        if [ "$related_pid" != "$pid" ]; then
          kill -TERM "$related_pid" 2>/dev/null || true
        fi
      done

      sleep 1

      for related_pid in $(_ue_related_pids); do
        if [ "$related_pid" != "$pid" ]; then
          kill -KILL "$related_pid" 2>/dev/null || true
        fi
      done

      rm -f "$pid_file"
    }

    ue-start() {
      local pulse_runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      local pid_file="$(_ue_pid_file)"
      local editor_pid=""
      local status=0

      _ue_cleanup_on_signal() {
        if [ -n "$editor_pid" ] && _ue_pid_alive "$editor_pid"; then
          kill -TERM "-$editor_pid" 2>/dev/null || kill -TERM "$editor_pid" 2>/dev/null || true
        fi
      }

      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      export VK_ICD_FILENAMES=/run/host/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json
      export LD_LIBRARY_PATH="/run/host/run/opengl-driver/lib:''${LD_LIBRARY_PATH:-}"
      export SDL_AUDIODRIVER=pulseaudio
      export PULSE_SERVER="unix:''${pulse_runtime}/pulse/native"

      cd /workspace/projects/UE-5.7.4/Engine/Binaries/Linux || return

      if command -v setsid >/dev/null 2>&1; then
        setsid ./UnrealEditor "$@" &
      else
        ./UnrealEditor "$@" &
      fi

      editor_pid="$!"
      printf '%s\n' "$editor_pid" > "$pid_file"

      trap _ue_cleanup_on_signal HUP INT TERM EXIT
      wait "$editor_pid"
      status="$?"
      trap - HUP INT TERM EXIT

      rm -f "$pid_file"
      return "$status"
    }
  '';

  t3codeVitePlusEnv = pkgs.writeText "t3code-vite-plus-env.sh" ''
    export VP_HOME="''${VP_HOME:-$HOME/.vite-plus}"

    case ":''${PATH}:" in
      *":''${VP_HOME}/bin:"*) ;;
      *) export PATH="''${VP_HOME}/bin:''${PATH}" ;;
    esac

    unset LD_LIBRARY_PATH
    unset NIX_LD_LIBRARY_PATH
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
    additional_packages="alsa-lib alsa-plugins-pulseaudio pipewire-libs pulseaudio-libs pango libxkbcommon libgbm libXrandr libXdamage libXcomposite-devel at-spi2-atk libxml2-devel nss.x86_64 vulkan-tools xdg-utils procps-ng util-linux gawk"

    home=${homeDirectory}/.local/share/distrobox/homes/unreal-dev

    volume="${homeDirectory}/Projects:/workspace/projects"
    volume="${unrealDevAliases}:/opt/distrobox-aliases/aliases.sh:ro"
    volume="${hostBrowserWrappers}:/opt/distrobox-browser:ro"

    init_hooks="grep -qxF 'source /opt/distrobox-aliases/aliases.sh' ~/.bashrc || echo 'source /opt/distrobox-aliases/aliases.sh' >> ~/.bashrc"
    init_hooks="grep -qxF 'source /opt/distrobox-aliases/aliases.sh' ~/.zshrc || echo 'source /opt/distrobox-aliases/aliases.sh' >> ~/.zshrc"
  '';

  t3codeDistroboxIniText = ''
    [t3code-dev]
    pull=true
    image=quay.io/fedora/fedora-toolbox:43
    init=false
    root=false
    replace=false
    start_now=false
    nvidia=true
    additional_packages="bash zsh curl ca-certificates git gh git-lfs gcc gcc-c++ make python3 pkgconf-pkg-config rust cargo rustfmt gtk3 glib2 nss nspr atk at-spi2-atk cups-libs dbus-libs pango cairo alsa-lib libX11 libXcomposite libXcursor libXdamage libXext libXfixes libXi libXinerama libXrandr libxcb libxkbcommon mesa-libgbm libdrm systemd-libs vulkan-loader xdg-utils procps-ng util-linux"

    home=${homeDirectory}/.local/share/distrobox/homes/t3code-dev

    volume="${homeDirectory}/Projects:/workspace/projects"
    volume="${t3codeVitePlusEnv}:/opt/t3code/vite-plus-env.sh:ro"

    init_hooks="touch ~/.bashrc; grep -qxF 'source /opt/t3code/vite-plus-env.sh' ~/.bashrc || echo 'source /opt/t3code/vite-plus-env.sh' >> ~/.bashrc"
    init_hooks="touch ~/.bash_profile; grep -qxF 'source /opt/t3code/vite-plus-env.sh' ~/.bash_profile || echo 'source /opt/t3code/vite-plus-env.sh' >> ~/.bash_profile"
    init_hooks="touch ~/.profile; grep -qxF 'source /opt/t3code/vite-plus-env.sh' ~/.profile || echo 'source /opt/t3code/vite-plus-env.sh' >> ~/.profile"
    init_hooks="touch ~/.zshrc; grep -qxF 'source /opt/t3code/vite-plus-env.sh' ~/.zshrc || echo 'source /opt/t3code/vite-plus-env.sh' >> ~/.zshrc"
  '';

  distroboxConfig = distroboxIniText + t3codeDistroboxIniText;

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
    podman-compose
    passt
    podman-tui
  ];

  systemd.user.services.distrobox-assemble = {
    description = "Create declared Distrobox containers";
    environment.PATH = lib.mkForce "/run/wrappers/bin:${distroboxAssemblePath}";

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.distrobox}/bin/distrobox-assemble create --file /etc/distrobox/distrobox.ini";
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

  environment.etc."distrobox/distrobox.ini".text = distroboxConfig;
}

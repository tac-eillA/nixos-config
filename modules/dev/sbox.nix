{ config, lib, pkgs, ... }:

let
  cfg = config.programs.sbox;

  dotnetSdk =
    if builtins.hasAttr "dotnet-sdk_10" pkgs then
      pkgs.dotnet-sdk_10
    else if builtins.hasAttr "dotnetCorePackages" pkgs && builtins.hasAttr "sdk_10_0" pkgs.dotnetCorePackages then
      pkgs.dotnetCorePackages.sdk_10_0
    else
      throw "programs.sbox requires a .NET 10 SDK package in nixpkgs.";

  runtimeLibs = with pkgs; [
    stdenv.cc.cc
    glibc
    glibcLocales
    zlib
    zstd
    bzip2
    xz
    openssl
    curl
    libxml2
    icu
    krb5
    libuuid

    fontconfig
    freetype
    expat
    dbus
    nss
    nspr
    glib
    libgbm

    systemd
    udev
    libinput
    libevdev
    libusb1

    alsa-lib
    libpulseaudio
    pipewire

    libdrm
    libglvnd
    vulkan-loader
    vulkan-validation-layers
    wayland
    libxkbcommon
    SDL2

    gtk3
    pango
    cairo
    gdk-pixbuf
    atk
    at-spi2-core
    at-spi2-atk

    libX11
    libXext
    libXcursor
    libXi
    libXrandr
    libXrender
    libXinerama
    libXfixes
    libXcomposite
    libXdamage
    libXtst
    libSM
    libICE
    libxcb
    libXxf86vm
    xcbutil
    xcbutilwm
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
  ];

  buildTools = with pkgs; [
    bashInteractive
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    gnutar
    gzip
    bzip2
    xz
    unzip
    zip
    p7zip
    patch
    which
    file
    tree
    jq

    git
    git-lfs
    openssh
    cacert
    curl
    wget
    rsync

    cmake
    ninja
    pkg-config
    clang
    llvm
    lld
    mold
    gcc
    ccache
    lldb

    dotnetSdk
    python3
    perl

    util-linux
    procps
    patchelf
    lsof
    strace

    vulkan-tools
    mesa-demos
    renderdoc
  ];

  runtimeLibraryPath = lib.makeLibraryPath runtimeLibs;

  sboxEnvVars = ''
    export LANG="''${LANG:-C.UTF-8}"
    export LC_ALL="''${LC_ALL:-C.UTF-8}"

    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export GIT_SSL_CAINFO="$SSL_CERT_FILE"

    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    export DOTNET_CLI_HOME="''${DOTNET_CLI_HOME:-$HOME/.dotnet}"
    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=0

    export SBOX_ROOT="''${SBOX_ROOT:-${cfg.engineRoot}}"
    export SBOX_REF="''${SBOX_REF:-${cfg.engineRef}}"
    export SBOX_CONFIG="''${SBOX_CONFIG:-${cfg.buildConfig}}"

    export CCACHE_DIR="''${CCACHE_DIR:-$HOME/.cache/ccache}"

    export NIX_LD="${lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"}"
    export NIX_LD_LIBRARY_PATH="${runtimeLibraryPath}:''${NIX_LD_LIBRARY_PATH:-}"
    export LD_LIBRARY_PATH="${runtimeLibraryPath}:''${LD_LIBRARY_PATH:-}"

    mkdir -p "$DOTNET_CLI_HOME" "$CCACHE_DIR" 2>/dev/null || true
  '';

  sboxFhs = pkgs.buildFHSEnv {
    name = "sbox-fhs";

    targetPkgs =
      _:
      buildTools
      ++ runtimeLibs
      ++ cfg.extraPackages
      ++ [
        pkgs.mesa
        pkgs.libGL
      ];

    extraOutputsToInstall = [
      "out"
      "bin"
      "lib"
      "dev"
    ];

    profile = sboxEnvVars;

    runScript = "bash";
  };

  mkSboxScript =
    name: body:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail

      exec ${sboxFhs}/bin/sbox-fhs -lc ${lib.escapeShellArg ''
        set -euo pipefail
        ${sboxEnvVars}
        ${body}
      ''} -- "$@"
    '';

  needEngine = ''
    if [ ! -d "$SBOX_ROOT" ]; then
      echo "SBOX_ROOT does not exist: $SBOX_ROOT" >&2
      echo "Run: sbox-clone" >&2
      exit 1
    fi

    if [ ! -f "$SBOX_ROOT/engine/Tools/SboxBuild/SboxBuild.csproj" ]; then
      echo "This does not look like a Facepunch/sbox-public checkout: $SBOX_ROOT" >&2
      exit 1
    fi
  '';

  sboxBuildFn = ''
    sboxbuild() {
      dotnet run --project engine/Tools/SboxBuild/SboxBuild.csproj -- "$@"
    }
  '';

  sboxShaderCompilerCompatFn = ''
    ensure_sbox_shadercompiler_compat() {
      local managed_dir="$SBOX_ROOT/game/bin/managed"
      local expected="$managed_dir/shadercompiler.exe"
      local native_linux="$managed_dir/ShaderCompiler"
      local fake_argv0="$SBOX_ROOT/game/.linux-compat/bin\\managed/shadercompiler.exe"

      if [ -x "$native_linux" ]; then
        mkdir -p "$SBOX_ROOT/game/.linux-compat"
        cat > "$expected" <<EOF
#!/usr/bin/env bash
exec -a "$fake_argv0" "$native_linux" "\$@"
EOF
        chmod +x "$expected"
      fi
    }
  '';

  sboxSteamCompatFn = ''
    ensure_sbox_steam_compat() {
      local game_dir="$SBOX_ROOT/game"
      local linux_steam_api="$game_dir/bin/linuxsteamrt64/libsteam_api.so"
      local weird_win_path="$SBOX_ROOT/game\\bin\\win64\\steam_api64.dll"

      if [ -f "$linux_steam_api" ]; then
        ln -sf "$linux_steam_api" "$weird_win_path"
      fi
    }
  '';

  sbox-shell = pkgs.writeShellScriptBin "sbox-shell" ''
    set -euo pipefail

    export SBOX_ROOT="''${SBOX_ROOT:-${cfg.engineRoot}}"
    export SBOX_REF="''${SBOX_REF:-${cfg.engineRef}}"
    export SBOX_CONFIG="''${SBOX_CONFIG:-${cfg.buildConfig}}"

    exec ${sboxFhs}/bin/sbox-fhs "$@"
  '';

  sbox-clone = mkSboxScript "sbox-clone" ''
    mkdir -p "$(dirname "$SBOX_ROOT")"

    if [ -d "$SBOX_ROOT/.git" ]; then
      echo "sbox-public already exists at: $SBOX_ROOT"
      echo "To update it, run: sbox-update"
      exit 0
    fi

    echo "Cloning Facepunch/sbox-public..."
    echo "SBOX_ROOT=$SBOX_ROOT"
    echo "SBOX_REF=$SBOX_REF"
    echo

    git lfs install

    git clone \
      --branch "$SBOX_REF" \
      --single-branch \
      https://github.com/Facepunch/sbox-public.git \
      "$SBOX_ROOT"

    cd "$SBOX_ROOT"
    git lfs pull || true

    echo
    echo "Clone complete."
    echo
    echo "Next:"
    echo "  sbox-bootstrap"
    echo "  sbox-run"
  '';

  sbox-update = mkSboxScript "sbox-update" ''
    ${needEngine}

    cd "$SBOX_ROOT"

    git fetch --all --tags --prune
    git pull --ff-only
    git lfs pull || true
  '';

  sbox-bootstrap = mkSboxScript "sbox-bootstrap" ''
    ${needEngine}
    ${sboxBuildFn}
    ${sboxShaderCompilerCompatFn}

    cd "$SBOX_ROOT"

    sboxbuild build --config "$SBOX_CONFIG"
    ensure_sbox_shadercompiler_compat
    sboxbuild build-shaders
    sboxbuild build-content
  '';

  sbox-build = mkSboxScript "sbox-build" ''
    ${needEngine}
    ${sboxBuildFn}

    cd "$SBOX_ROOT"
    sboxbuild build --config "$SBOX_CONFIG" "$@"
  '';

  sbox-build-shaders = mkSboxScript "sbox-build-shaders" ''
    ${needEngine}
    ${sboxBuildFn}
    ${sboxShaderCompilerCompatFn}

    cd "$SBOX_ROOT"
    ensure_sbox_shadercompiler_compat
    sboxbuild build-shaders "$@"
  '';

  sbox-build-content = mkSboxScript "sbox-build-content" ''
    ${needEngine}
    ${sboxBuildFn}

    cd "$SBOX_ROOT"
    sboxbuild build-content "$@"
  '';

  sbox-rebuild = mkSboxScript "sbox-rebuild" ''
    ${needEngine}
    ${sboxBuildFn}
    ${sboxShaderCompilerCompatFn}

    cd "$SBOX_ROOT"

    sboxbuild build --config "$SBOX_CONFIG"
    ensure_sbox_shadercompiler_compat
    sboxbuild build-shaders
    sboxbuild build-content
  '';

  sbox-solution = mkSboxScript "sbox-solution" ''
    ${needEngine}
    printf '%s\n' "$SBOX_ROOT/engine/Sandbox-Engine.slnx"
  '';

  sbox-run = mkSboxScript "sbox-run" ''
    ${needEngine}
    ${sboxSteamCompatFn}

    game_dir="$SBOX_ROOT/game"

    if [ ! -d "$game_dir" ]; then
      echo "Expected game directory was not found: $game_dir" >&2
      exit 1
    fi

    export STEAM_COMPAT_CLIENT_INSTALL_PATH="''${STEAM_COMPAT_CLIENT_INSTALL_PATH:-$HOME/.local/share/Steam}"
    export STEAM_RUNTIME="''${STEAM_RUNTIME:-0}"

    if [ -d "$game_dir/bin/linuxsteamrt64" ]; then
      export LD_LIBRARY_PATH="$game_dir/bin/linuxsteamrt64:''${LD_LIBRARY_PATH:-}"
      export PATH="$game_dir/bin/linuxsteamrt64:''${PATH:-}"
    fi

    if [ ! -f "$game_dir/steam_appid.txt" ]; then
      printf '%s\n' '590830' > "$game_dir/steam_appid.txt"
    fi

    ensure_sbox_steam_compat

    cd "$game_dir"

    have_linux_editor_natives=0
    if [ -f "$game_dir/bin/linuxsteamrt64/libtoolframework2.so" ]; then
      have_linux_editor_natives=1
    fi

    wants_editor=0
    for arg in "$@"
    do
      case "$arg" in
        -project|-test)
          wants_editor=1
          break
          ;;
      esac
    done

    if [ "$wants_editor" -eq 1 ]; then
      if [ "$have_linux_editor_natives" -eq 1 ] && [ -x "$game_dir/sbox-dev" ]; then
        exec "$game_dir/sbox-dev" "$@"
      fi

      echo "The public Linux sbox-public build is missing editor native libraries." >&2
      echo "Expected at least: $game_dir/bin/linuxsteamrt64/libtoolframework2.so" >&2
      echo "This module currently supports runtime launch only for public Linux source builds." >&2
      exit 1
    fi

    for candidate in \
      "$game_dir/Sandbox" \
      "$game_dir/sbox" \
      "$game_dir/sbox-standalone" \
      "$game_dir/Sandbox.exe" \
      "$game_dir/sbox.exe"
    do
      if [ ! -x "$candidate" ]; then
        continue
      fi

      case "$candidate" in
        *.exe)
          if command -v wine64 >/dev/null 2>&1; then
            exec wine64 "$candidate" "$@"
          fi
          echo "Found a Windows executable but wine64 is not installed: $candidate" >&2
          exit 1
          ;;
        *)
          exec "$candidate" "$@"
          ;;
      esac
    done

    echo "No obvious s&box executable was found in $SBOX_ROOT/game." >&2
    echo "Build first with: sbox-bootstrap" >&2
    echo "If the build succeeded, inspect $SBOX_ROOT/game for the produced binary layout." >&2
    exit 1
  '';

  sbox-doctor = mkSboxScript "sbox-doctor" ''
    echo "s&box / NixOS diagnostic"
    echo "======================="
    echo "SBOX_ROOT=$SBOX_ROOT"
    echo "SBOX_REF=$SBOX_REF"
    echo "SBOX_CONFIG=$SBOX_CONFIG"
    echo

    echo "Tooling:"
    command -v git
    command -v git-lfs
    command -v dotnet
    command -v clang
    command -v cmake
    command -v ninja
    command -v vulkaninfo || true
    echo

    echo ".NET:"
    dotnet --info || true
    echo

    echo "Vulkan:"
    vulkaninfo --summary || true
    echo

    if [ -d "$SBOX_ROOT/.git" ]; then
      echo "Engine checkout: OK"
      cd "$SBOX_ROOT"
      git remote -v | sed 's/^/  /'
      git status --short --branch | sed 's/^/  /'
    else
      echo "Engine checkout: missing"
    fi

    echo

    if [ -d "$SBOX_ROOT/game" ]; then
      echo "game/ directory: found"
      find "$SBOX_ROOT/game" -maxdepth 2 \( -type f -o -type l \) | sed 's/^/  /' | head -n 50 || true
    else
      echo "game/ directory: missing"
    fi
  '';

  sboxDesktopItem = pkgs.makeDesktopItem {
    name = "sbox-editor";
    desktopName = "s&box";
    genericName = "Game Engine Editor";
    comment = "Launch s&box runtime through the NixOS source-build wrapper";
    exec = "sbox-run %f";
    terminal = false;
    categories = [
      "Development"
      "IDE"
      "Graphics"
      "Game"
    ];
  };

  wrapperPackages = [
    sbox-shell
    sbox-clone
    sbox-update
    sbox-bootstrap
    sbox-build
    sbox-build-shaders
    sbox-build-content
    sbox-rebuild
    sbox-solution
    sbox-run
    sbox-doctor
  ];
in
{
  options.programs.sbox = {
    enable = lib.mkEnableOption "s&box source-build workstation support on NixOS";

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "allie";
      description = "Optional user to add to video/render/input/gamemode groups.";
    };

    engineRoot = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/src/sbox-public";
      example = "$HOME/src/sbox-public";
      description = "Default Facepunch/sbox-public source checkout path used by wrapper commands.";
    };

    engineRef = lib.mkOption {
      type = lib.types.str;
      default = "master";
      example = "master";
      description = "Default Facepunch/sbox-public branch, tag, or ref used by sbox-clone.";
    };

    buildConfig = lib.mkOption {
      type = lib.types.str;
      default = "Developer";
      example = "Release";
      description = "Default SboxBuild configuration passed to the main build step.";
    };

    installBuildTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install s&box build/debug tools into the system profile.";
    };

    installWrappers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install sbox-* wrapper commands globally.";
    };

    enableDesktopEntry = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install a desktop entry that calls sbox-run for the public Linux runtime path.";
    };

    enableNixLd = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add s&box runtime libraries to programs.nix-ld.";
    };

    enableGraphics = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable NixOS graphics/Vulkan support commonly needed by the editor/runtime.";
    };

    enablePipeWire = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable PipeWire audio support with ALSA/Pulse/JACK compatibility.";
    };

    enableGamemode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable gamemode so the module remains standalone.";
    };

    enableKernelTweaks = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Apply inotify/map-count tweaks useful for large source trees and editor content.";
    };

    enableSteamCompat = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable programs.steam from this module. Leave false if another module already handles Steam.";
    };

    gpu = lib.mkOption {
      type = lib.types.enum [
        "generic"
        "nvidia"
        "amd"
        "intel"
      ];
      default = "generic";
      description = "GPU-specific graphics package bias. This does not install full driver stacks by itself.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.wineWowPackages.staging ]";
      description = "Additional packages to expose inside the s&box FHS wrapper.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
        message = "The s&box NixOS module currently expects x86_64-linux.";
      }
    ];

    environment.systemPackages =
      lib.optionals cfg.installBuildTools buildTools
      ++ lib.optionals cfg.installWrappers wrapperPackages
      ++ lib.optionals cfg.enableDesktopEntry [ sboxDesktopItem ];

    hardware.graphics = lib.mkIf cfg.enableGraphics {
      enable = lib.mkDefault true;
      enable32Bit = lib.mkDefault true;

      extraPackages =
        with pkgs;
        [
          vulkan-loader
          vulkan-validation-layers
        ]
        ++ lib.optionals (cfg.gpu == "intel") [
          intel-media-driver
        ];
    };

    programs.nix-ld = lib.mkIf cfg.enableNixLd {
      enable = lib.mkDefault true;
      libraries = runtimeLibs;
    };

    security.rtkit.enable = lib.mkIf cfg.enablePipeWire (lib.mkDefault true);

    services.pipewire = lib.mkIf cfg.enablePipeWire {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      jack.enable = lib.mkDefault true;
    };

    programs.gamemode.enable = lib.mkIf cfg.enableGamemode (lib.mkDefault true);

    programs.steam.enable = lib.mkIf cfg.enableSteamCompat (lib.mkDefault true);

    # boot.kernel.sysctl = lib.mkIf cfg.enableKernelTweaks {
    #   "fs.inotify.max_user_watches" = lib.mkDefault 1048576;
    #   "fs.inotify.max_user_instances" = lib.mkDefault 8192;
    #   "vm.max_map_count" = lib.mkDefault 1048576;
    # };

    users.users = lib.mkIf (cfg.user != null) {
      "${cfg.user}".extraGroups = [
        "video"
        "render"
        "input"
      ]
      ++ lib.optionals cfg.enableGamemode [ "gamemode" ];
    };
  };
}

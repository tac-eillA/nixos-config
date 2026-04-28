{ config, lib, pkgs, ... }:

let
  cfg = config.programs.unrealEngine;

  runtimeLibs = with pkgs; [
    # Core C/C++ runtime and compression/networking
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

    # Desktop/runtime basics
    fontconfig
    freetype
    expat
    dbus
    nss
    nspr

    # Audio
    alsa-lib
    libpulseaudio
    pipewire

    # Graphics / Vulkan / Wayland / SDL
    libdrm
    libglvnd
    vulkan-loader
    vulkan-validation-layers
    wayland
    libxkbcommon
    SDL2

    # GTK-ish editor/tool dependencies
    gtk3
    pango
    cairo
    gdk-pixbuf
    atk
    at-spi2-core
    at-spi2-atk

    # X11
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
    # Shell/core tools
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

    # Source control / network
    git
    git-lfs
    openssh
    cacert
    curl
    wget
    rsync

    # Build tooling
    gnumake
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

    # Language runtimes/tools Unreal may touch
    python3
    perl
    mono
    dotnet-sdk_8
    jdk17

    # Debug/inspection
    util-linux
    procps
    patchelf
    lsof
    strace

    # Graphics/dev helpers
    vulkan-tools
    mesa-demos
    renderdoc
  ];

  runtimeLibraryPath = lib.makeLibraryPath runtimeLibs;

  ueJobDefault =
    if cfg.jobs == null
    then "$(nproc)"
    else toString cfg.jobs;

  ueEnvVars = ''
    export LANG="''${LANG:-C.UTF-8}"
    export LC_ALL="''${LC_ALL:-C.UTF-8}"

    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export GIT_SSL_CAINFO="$SSL_CERT_FILE"

    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    export DOTNET_CLI_HOME="''${DOTNET_CLI_HOME:-$HOME/.dotnet}"
    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=0

    export UE_ROOT="''${UE_ROOT:-${cfg.engineRoot}}"
    export UE_REF="''${UE_REF:-${cfg.engineRef}}"
    export UE_PROJECTS="''${UE_PROJECTS:-${cfg.projectsDir}}"
    export UE_JOBS="''${UE_JOBS:-${ueJobDefault}}"

    export CCACHE_DIR="''${CCACHE_DIR:-$HOME/.cache/ccache}"

    export NIX_LD="${lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"}"
    export NIX_LD_LIBRARY_PATH="${runtimeLibraryPath}:''${NIX_LD_LIBRARY_PATH:-}"
    export LD_LIBRARY_PATH="${runtimeLibraryPath}:''${LD_LIBRARY_PATH:-}"

    mkdir -p "$UE_PROJECTS" "$DOTNET_CLI_HOME" "$CCACHE_DIR" 2>/dev/null || true
  '';

  ueFhs = pkgs.buildFHSEnv {
    name = "ue-fhs";

    targetPkgs =
      _:
      buildTools
      ++ runtimeLibs
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

    profile = ueEnvVars;

    runScript = "bash";
  };

  mkUeScript =
    name: body:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail

      exec ${ueFhs}/bin/ue-fhs -lc ${lib.escapeShellArg ''
        set -euo pipefail
        ${ueEnvVars}
        ${body}
      ''} -- "$@"
    '';

  needEngine = ''
    if [ ! -d "$UE_ROOT" ]; then
      echo "UE_ROOT does not exist: $UE_ROOT" >&2
      echo "Run: ue-clone" >&2
      exit 1
    fi

    if [ ! -x "$UE_ROOT/Setup.sh" ]; then
      echo "This does not look like an UnrealEngine source checkout: $UE_ROOT" >&2
      exit 1
    fi
  '';

  ue-shell = pkgs.writeShellScriptBin "ue-shell" ''
    set -euo pipefail

    export UE_ROOT="''${UE_ROOT:-${cfg.engineRoot}}"
    export UE_REF="''${UE_REF:-${cfg.engineRef}}"
    export UE_PROJECTS="''${UE_PROJECTS:-${cfg.projectsDir}}"
    export UE_JOBS="''${UE_JOBS:-${ueJobDefault}}"

    exec ${ueFhs}/bin/ue-fhs "$@"
  '';

  ue-clone = mkUeScript "ue-clone" ''
    mkdir -p "$(dirname "$UE_ROOT")"

    if [ -d "$UE_ROOT/.git" ]; then
      echo "UnrealEngine already exists at: $UE_ROOT"
      echo "To update it, run: ue-update"
      exit 0
    fi

    echo "Cloning Unreal Engine from Epic GitHub..."
    echo "UE_ROOT=$UE_ROOT"
    echo "UE_REF=$UE_REF"
    echo

    git lfs install

    git clone \
      --branch "$UE_REF" \
      --single-branch \
      git@github.com:EpicGames/UnrealEngine.git \
      "$UE_ROOT"

    cd "$UE_ROOT"
    git lfs pull || true

    echo
    echo "Clone complete."
    echo
    echo "Next:"
    echo "  ue-setup"
    echo "  ue-generate"
    echo "  ue-build"
  '';

  ue-update = mkUeScript "ue-update" ''
    ${needEngine}

    cd "$UE_ROOT"

    git fetch --all --tags --prune
    git pull --ff-only
    git lfs pull || true
  '';

  ue-setup = mkUeScript "ue-setup" ''
    ${needEngine}

    cd "$UE_ROOT"
    exec ./Setup.sh "$@"
  '';

  ue-generate = mkUeScript "ue-generate" ''
    ${needEngine}

    cd "$UE_ROOT"
    exec ./GenerateProjectFiles.sh "$@"
  '';

  ue-build = mkUeScript "ue-build" ''
    ${needEngine}

    cd "$UE_ROOT"

    echo "Building Unreal Engine with $UE_JOBS jobs..."
    exec make -j"$UE_JOBS" "$@"
  '';

  ue-rebuild = mkUeScript "ue-rebuild" ''
    ${needEngine}

    cd "$UE_ROOT"

    ./Setup.sh
    ./GenerateProjectFiles.sh
    exec make -j"$UE_JOBS" "$@"
  '';

  ue-editor = mkUeScript "ue-editor" ''
    ${needEngine}

    cd "$UE_ROOT"

    editor="./Engine/Binaries/Linux/UnrealEditor"

    if [ ! -x "$editor" ]; then
      echo "UnrealEditor binary not found or not executable." >&2
      echo "Expected: $UE_ROOT/Engine/Binaries/Linux/UnrealEditor" >&2
      echo "Run: ue-setup && ue-generate && ue-build" >&2
      exit 1
    fi

    exec "$editor" "$@"
  '';

  ue-open-project = mkUeScript "ue-open-project" ''
    ${needEngine}

    if [ "$#" -lt 1 ]; then
      echo "Usage: ue-open-project /path/to/Game.uproject [UnrealEditor args...]" >&2
      exit 2
    fi

    project="$1"
    shift

    if [ ! -f "$project" ]; then
      echo "Project file does not exist: $project" >&2
      exit 1
    fi

    cd "$UE_ROOT"
    exec ./Engine/Binaries/Linux/UnrealEditor "$project" "$@"
  '';

  ue-project-files = mkUeScript "ue-project-files" ''
    ${needEngine}

    if [ "$#" -lt 1 ]; then
      echo "Usage: ue-project-files /path/to/Game.uproject [GenerateProjectFiles args...]" >&2
      exit 2
    fi

    project="$1"
    shift

    if [ ! -f "$project" ]; then
      echo "Project file does not exist: $project" >&2
      exit 1
    fi

    cd "$UE_ROOT"
    exec ./GenerateProjectFiles.sh -project="$project" -game "$@"
  '';

  ue-doctor = mkUeScript "ue-doctor" ''
    echo "Unreal/NixOS diagnostic"
    echo "======================="
    echo "UE_ROOT=$UE_ROOT"
    echo "UE_REF=$UE_REF"
    echo "UE_PROJECTS=$UE_PROJECTS"
    echo "UE_JOBS=$UE_JOBS"
    echo

    echo "Tooling:"
    command -v git
    command -v git-lfs
    command -v clang
    command -v cmake
    command -v ninja
    command -v make
    command -v python3
    command -v dotnet || true
    echo

    echo "Vulkan:"
    command -v vulkaninfo || true
    vulkaninfo --summary || true
    echo

    if [ -d "$UE_ROOT/.git" ]; then
      echo "Engine checkout: OK"
      cd "$UE_ROOT"
      git remote -v | sed 's/^/  /'
      git status --short --branch | sed 's/^/  /'
    else
      echo "Engine checkout: missing"
    fi

    echo

    editor="$UE_ROOT/Engine/Binaries/Linux/UnrealEditor"
    if [ -x "$editor" ]; then
      echo "UnrealEditor binary: OK"
      echo "Checking missing dynamic libraries:"
      if ldd "$editor" | grep -i "not found"; then
        echo "Missing libraries were reported above." >&2
        exit 1
      else
        echo "No missing libraries reported by ldd."
      fi
    else
      echo "UnrealEditor binary: not built yet"
    fi
  '';

  ueDesktopItem = pkgs.makeDesktopItem {
    name = "unreal-editor";
    desktopName = "Unreal Editor";
    genericName = "Game Engine Editor";
    comment = "Launch Unreal Editor through the NixOS Unreal FHS wrapper";
    exec = "ue-editor %f";
    terminal = false;
    categories = [
      "Development"
      "IDE"
      "Graphics"
      "Game"
    ];
    mimeTypes = [ "application/x-uproject" ];
  };

  wrapperPackages = [
    ue-shell
    ue-clone
    ue-update
    ue-setup
    ue-generate
    ue-build
    ue-rebuild
    ue-editor
    ue-open-project
    ue-project-files
    ue-doctor
  ];
in
{
  options.programs.unrealEngine = {
    enable = lib.mkEnableOption "Unreal Engine source-build workstation support on NixOS";

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "allie";
      description = "Optional user to add to video/render/input/gamemode groups.";
    };

    engineRoot = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/src/UnrealEngine";
      example = "$HOME/src/UnrealEngine";
      description = "Default Unreal Engine source checkout path used by wrapper commands.";
    };

    engineRef = lib.mkOption {
      type = lib.types.str;
      default = "release";
      example = "5.6.0-release";
      description = "Default EpicGames/UnrealEngine branch, tag, or ref used by ue-clone.";
    };

    projectsDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/UnrealProjects";
      example = "$HOME/UnrealProjects";
      description = "Default Unreal project directory created by the wrapper environment.";
    };

    jobs = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 16;
      description = "Default make job count for ue-build. Null means use nproc at runtime.";
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

    installBuildTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Unreal build/debug tools into the system profile.";
    };

    installWrappers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install ue-* wrapper commands globally.";
    };

    enableDesktopEntry = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install a desktop entry for Unreal Editor that calls ue-editor.";
    };

    enableNixLd = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add Unreal runtime libraries to programs.nix-ld.";
    };

    enableGraphics = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable NixOS graphics/Vulkan support needed by Unreal Editor.";
    };

    enablePipeWire = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable PipeWire audio support with ALSA/Pulse/JACK compatibility.";
    };

    enableGamemode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable gamemode. Your gaming module already does this, but this keeps the module standalone.";
    };

    enableKernelTweaks = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Apply inotify/map-count tweaks useful for huge editor/source trees.";
    };

    enableSteamCompat = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable programs.steam from this module. Leave false if your gaming profile already handles Steam.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
        message = "The Unreal Engine NixOS module currently expects x86_64-linux.";
      }
    ];

    nixpkgs.config.allowUnfree = lib.mkDefault true;

    environment.systemPackages =
      lib.optionals cfg.installBuildTools buildTools
      ++ lib.optionals cfg.installWrappers wrapperPackages
      ++ lib.optionals cfg.enableDesktopEntry [ ueDesktopItem ];

    hardware.graphics = lib.mkIf cfg.enableGraphics {
      enable = lib.mkDefault true;
      enable32Bit = lib.mkDefault true;

      extraPackages =
        with pkgs;
        [
          vulkan-loader
          vulkan-validation-layers
        ]
        ++ lib.optionals (cfg.gpu == "amd") [
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

    programs.steam = lib.mkIf cfg.enableSteamCompat {
      enable = lib.mkDefault true;
      remotePlay.openFirewall = lib.mkDefault true;
      dedicatedServer.openFirewall = lib.mkDefault true;
    };

    # boot.kernel.sysctl = lib.mkIf cfg.enableKernelTweaks {
    #   "fs.inotify.max_user_watches" = lib.mkForce 1048576;
    #   "fs.inotify.max_user_instances" = lib.mkForce 1024;
    #   "vm.max_map_count" = lib.mkForce 1048576;
    # };

    users.users = lib.mkIf (cfg.user != null) {
      ${cfg.user}.extraGroups =
        [
          "video"
          "render"
          "input"
        ]
        ++ lib.optional cfg.enableGamemode "gamemode";
    };
  };
}

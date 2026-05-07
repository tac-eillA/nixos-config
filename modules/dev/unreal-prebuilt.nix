{ config, lib, pkgs, ... }:

let
  cfg = config.programs.unrealEnginePrebuilt;

  dotnetSdk =
    if pkgs ? dotnet-sdk_8
    then pkgs.dotnet-sdk_8
    else pkgs.dotnet-sdk;

  jdkPkg =
    if pkgs ? jdk17
    then pkgs.jdk17
    else pkgs.jdk;

  baseRuntimeLibs = with pkgs; [
    # Core C/C++ runtime and common binary deps
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

  installTools = with pkgs; [
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
    which
    file
    tree
    jq
    rsync
    curl
    wget
    cacert
    patchelf
    lsof
    strace
    util-linux
    procps
    pciutils
    usbutils
    vulkan-tools
    mesa-demos
  ];

  cppProjectTools = with pkgs; [
    git
    git-lfs
    openssh

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

    python3
    perl
    mono
    dotnetSdk
    jdkPkg
  ];

  runtimeLibs = baseRuntimeLibs ++ cfg.extraRuntimePackages;

  fhsPackages =
    installTools
    ++ runtimeLibs
    ++ lib.optionals cfg.enableCppTools cppProjectTools
    ++ cfg.extraFhsPackages;

  runtimeLibraryPath = lib.makeLibraryPath runtimeLibs;

  ueEnvVars = ''
    export LANG="''${LANG:-C.UTF-8}"
    export LC_ALL="''${LC_ALL:-C.UTF-8}"

    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export GIT_SSL_CAINFO="$SSL_CERT_FILE"

    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    export DOTNET_CLI_HOME="''${DOTNET_CLI_HOME:-$HOME/.dotnet}"
    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=0

    export UE_BIN_ROOT="''${UE_BIN_ROOT:-${cfg.engineRoot}}"
    export UE_PROJECTS="''${UE_PROJECTS:-${cfg.projectsDir}}"

    export CCACHE_DIR="''${CCACHE_DIR:-$HOME/.cache/ccache}"

    export NIX_LD="${lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"}"
    export NIX_LD_LIBRARY_PATH="${runtimeLibraryPath}:''${NIX_LD_LIBRARY_PATH:-}"
    export LD_LIBRARY_PATH="${runtimeLibraryPath}:''${LD_LIBRARY_PATH:-}"

    mkdir -p "$UE_PROJECTS" "$DOTNET_CLI_HOME" "$CCACHE_DIR" 2>/dev/null || true
  '';

  ueBinFhs = pkgs.buildFHSEnv {
    name = "ue-bin-fhs";

    targetPkgs = _: fhsPackages ++ [
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

      exec ${ueBinFhs}/bin/ue-bin-fhs -lc ${lib.escapeShellArg ''
        set -euo pipefail
        ${ueEnvVars}
        ${body}
      ''} -- "$@"
    '';

  needEngine = ''
    if [ ! -d "$UE_BIN_ROOT" ]; then
      echo "UE_BIN_ROOT does not exist: $UE_BIN_ROOT" >&2
      echo "Download the Unreal Engine Linux zip from Epic, then run:" >&2
      echo "  ue-bin-install ~/Downloads/UnrealEngine-*.zip" >&2
      exit 1
    fi

    if [ ! -f "$UE_BIN_ROOT/Engine/Binaries/Linux/UnrealEditor" ]; then
      echo "UnrealEditor was not found." >&2
      echo "Expected:" >&2
      echo "  $UE_BIN_ROOT/Engine/Binaries/Linux/UnrealEditor" >&2
      echo >&2
      echo "UE_BIN_ROOT should point to the extracted Unreal Engine directory that contains Engine/." >&2
      exit 1
    fi

    chmod +x "$UE_BIN_ROOT/Engine/Binaries/Linux/UnrealEditor" 2>/dev/null || true
  '';

  findProjectGenerator = ''
    generator=""

    if [ -x "$UE_BIN_ROOT/GenerateProjectFiles.sh" ]; then
      generator="$UE_BIN_ROOT/GenerateProjectFiles.sh"
    elif [ -x "$UE_BIN_ROOT/Engine/Build/BatchFiles/Linux/GenerateProjectFiles.sh" ]; then
      generator="$UE_BIN_ROOT/Engine/Build/BatchFiles/Linux/GenerateProjectFiles.sh"
    elif [ -f "$UE_BIN_ROOT/GenerateProjectFiles.sh" ]; then
      chmod +x "$UE_BIN_ROOT/GenerateProjectFiles.sh" 2>/dev/null || true
      generator="$UE_BIN_ROOT/GenerateProjectFiles.sh"
    elif [ -f "$UE_BIN_ROOT/Engine/Build/BatchFiles/Linux/GenerateProjectFiles.sh" ]; then
      chmod +x "$UE_BIN_ROOT/Engine/Build/BatchFiles/Linux/GenerateProjectFiles.sh" 2>/dev/null || true
      generator="$UE_BIN_ROOT/Engine/Build/BatchFiles/Linux/GenerateProjectFiles.sh"
    fi

    if [ -z "$generator" ]; then
      echo "Could not find GenerateProjectFiles.sh in this Unreal installed build." >&2
      echo "This may be normal for some prebuilt installs, especially for Blueprint-only use." >&2
      exit 1
    fi
  '';

  ue-bin-shell = pkgs.writeShellScriptBin "ue-bin-shell" ''
    set -euo pipefail

    export UE_BIN_ROOT="''${UE_BIN_ROOT:-${cfg.engineRoot}}"
    export UE_PROJECTS="''${UE_PROJECTS:-${cfg.projectsDir}}"

    exec ${ueBinFhs}/bin/ue-bin-fhs "$@"
  '';

  ue-bin-install = mkUeScript "ue-bin-install" ''
    if [ "$#" -lt 1 ]; then
      echo "Usage: ue-bin-install /path/to/UnrealEngine-Linux.zip [target-dir]" >&2
      echo >&2
      echo "Default target-dir:" >&2
      echo "  $UE_BIN_ROOT" >&2
      exit 2
    fi

    zipfile="$1"
    target="''${2:-$UE_BIN_ROOT}"

    if [ ! -f "$zipfile" ]; then
      echo "Zip file does not exist: $zipfile" >&2
      exit 1
    fi

    case "$zipfile" in
      *.zip) ;;
      *)
        echo "Warning: file does not end in .zip: $zipfile" >&2
        ;;
    esac

    if [ -e "$target" ] && [ "$(find "$target" -mindepth 1 -maxdepth 1 2>/dev/null | head -n 1)" ]; then
      echo "Target already exists and is not empty:" >&2
      echo "  $target" >&2
      echo >&2
      echo "Choose a different target or remove the existing directory." >&2
      exit 1
    fi

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    echo "Extracting:"
    echo "  $zipfile"
    echo "Temporary directory:"
    echo "  $tmp"
    echo

    unzip -q "$zipfile" -d "$tmp"

    candidate="$(find "$tmp" -path "*/Engine/Binaries/Linux/UnrealEditor" -type f | head -n 1 || true)"

    if [ -z "$candidate" ]; then
      echo "Could not find Engine/Binaries/Linux/UnrealEditor in the extracted zip." >&2
      echo "This does not look like the Unreal Engine Linux installed build zip." >&2
      exit 1
    fi

    srcRoot="''${candidate%/Engine/Binaries/Linux/UnrealEditor}"

    mkdir -p "$target"

    echo "Installing Unreal Engine prebuilt files:"
    echo "  from: $srcRoot"
    echo "  to:   $target"
    echo

    rsync -a "$srcRoot"/ "$target"/
    chmod +x "$target/Engine/Binaries/Linux/UnrealEditor" 2>/dev/null || true

    echo
    echo "Install complete."
    echo
    echo "Try:"
    echo "  ue-bin-doctor"
    echo "  ue-bin-editor"
  '';

  ue-bin-editor = mkUeScript "ue-bin-editor" ''
    ${needEngine}

    cd "$UE_BIN_ROOT"
    exec "$UE_BIN_ROOT/Engine/Binaries/Linux/UnrealEditor" "$@"
  '';

  ue-bin-open-project = mkUeScript "ue-bin-open-project" ''
    ${needEngine}

    if [ "$#" -lt 1 ]; then
      echo "Usage: ue-bin-open-project /path/to/Game.uproject [UnrealEditor args...]" >&2
      exit 2
    fi

    project="$1"
    shift

    if [ ! -f "$project" ]; then
      echo "Project file does not exist: $project" >&2
      exit 1
    fi

    cd "$UE_BIN_ROOT"
    exec "$UE_BIN_ROOT/Engine/Binaries/Linux/UnrealEditor" "$project" "$@"
  '';

  ue-bin-project-files = mkUeScript "ue-bin-project-files" ''
    ${needEngine}
    ${findProjectGenerator}

    if [ "$#" -lt 1 ]; then
      echo "Usage: ue-bin-project-files /path/to/Game.uproject [GenerateProjectFiles args...]" >&2
      exit 2
    fi

    project="$1"
    shift

    if [ ! -f "$project" ]; then
      echo "Project file does not exist: $project" >&2
      exit 1
    fi

    cd "$UE_BIN_ROOT"
    exec "$generator" -project="$project" -game "$@"
  '';

  ue-bin-doctor = mkUeScript "ue-bin-doctor" ''
    echo "Unreal Engine prebuilt / NixOS diagnostic"
    echo "=========================================="
    echo "UE_BIN_ROOT=$UE_BIN_ROOT"
    echo "UE_PROJECTS=$UE_PROJECTS"
    echo

    echo "System:"
    uname -a || true
    echo

    echo "glibc:"
    ldd --version | head -n 1 || true
    echo

    echo "Tooling:"
    command -v unzip || true
    command -v rsync || true
    command -v clang || true
    command -v cmake || true
    command -v ninja || true
    command -v python3 || true
    command -v dotnet || true
    echo

    echo "Vulkan:"
    command -v vulkaninfo || true
    vulkaninfo --summary || true
    echo

    if [ -d "$UE_BIN_ROOT" ]; then
      echo "Engine root: exists"
    else
      echo "Engine root: missing"
    fi

    editor="$UE_BIN_ROOT/Engine/Binaries/Linux/UnrealEditor"

    if [ -f "$editor" ]; then
      chmod +x "$editor" 2>/dev/null || true
      echo "UnrealEditor: found"
      echo
      echo "Checking missing dynamic libraries:"
      if ldd "$editor" | grep -i "not found"; then
        echo
        echo "Missing libraries were reported above." >&2
        echo "Add them with programs.unrealEnginePrebuilt.extraRuntimePackages." >&2
        exit 1
      else
        echo "No missing libraries reported by ldd."
      fi
    else
      echo "UnrealEditor: missing"
      echo "Expected: $editor"
    fi
  '';

  ueDesktopItem = pkgs.makeDesktopItem {
    name = "unreal-editor-prebuilt";
    desktopName = "Unreal Editor";
    genericName = "Game Engine Editor";
    comment = "Launch Unreal Editor prebuilt Linux binary through a NixOS FHS wrapper";
    exec = "ue-bin-editor %f";
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
    ue-bin-shell
    ue-bin-install
    ue-bin-editor
    ue-bin-open-project
    ue-bin-project-files
    ue-bin-doctor
  ];
in
{
  options.programs.unrealEnginePrebuilt = {
    enable = lib.mkEnableOption "Unreal Engine prebuilt Linux installed-build support on NixOS";

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "allison";
      description = "Optional user to add to video/render/input/gamemode groups.";
    };

    engineRoot = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/Applications/UnrealEngine";
      example = "$HOME/Applications/UnrealEngine-5.6";
      description = ''
        Runtime path to the extracted Unreal Engine prebuilt Linux install.
        This directory should contain Engine/Binaries/Linux/UnrealEditor.
        You can override this at runtime with UE_BIN_ROOT.
      '';
    };

    projectsDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/UnrealProjects";
      example = "$HOME/UnrealProjects";
      description = "Default Unreal project directory created by the wrapper environment.";
    };

    gpu = lib.mkOption {
      type = lib.types.enum [
        "generic"
        "nvidia"
        "amd"
        "intel"
      ];
      default = "generic";
      description = "GPU-specific graphics package bias. This does not install the full vendor driver stack by itself.";
    };

    installWrappers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install ue-bin-* wrapper commands globally.";
    };

    enableDesktopEntry = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install a desktop entry for Unreal Editor that calls ue-bin-editor.";
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

    enableAudio = lib.mkOption {
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
      description = "Apply inotify/map-count tweaks useful for large editor/project trees.";
    };

    enableCppTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include C++ project toolchain packages inside the Unreal FHS wrapper.";
    };

    installCppToolsGlobally = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install C++ project toolchain packages globally. Usually unnecessary if you already have a dev profile.";
    };

    extraRuntimePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "with pkgs; [ libsecret ]";
      description = "Additional runtime libraries added to LD_LIBRARY_PATH and nix-ld.";
    };

    extraFhsPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "with pkgs; [ libsecret ]";
      description = "Additional packages available inside the Unreal FHS wrapper.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
        message = "The Unreal Engine prebuilt Linux module currently expects x86_64-linux.";
      }
    ];

    nixpkgs.config.allowUnfree = lib.mkDefault true;

    environment.systemPackages =
      lib.optionals cfg.installWrappers wrapperPackages
      ++ lib.optionals cfg.enableDesktopEntry [ ueDesktopItem ]
      ++ lib.optionals cfg.installCppToolsGlobally cppProjectTools;

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

    security.rtkit.enable = lib.mkIf cfg.enableAudio (lib.mkDefault true);

    services.pipewire = lib.mkIf cfg.enableAudio {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      jack.enable = lib.mkDefault true;
    };

    programs.gamemode.enable = lib.mkIf cfg.enableGamemode (lib.mkDefault true);

    # boot.kernel.sysctl = lib.mkIf cfg.enableKernelTweaks {
    #   "fs.inotify.max_user_watches" = lib.mkDefault 1048576;
    #   "vm.max_map_count" = lib.mkDefault 1048576;
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

{ appimageTools
, fetchurl
, lib
, ...
}:

let
  appimageVersions = builtins.fromJSON (builtins.readFile ./appimage-versions.json);
  release = appimageVersions.lmstudio;
  pname = "lmstudio";
  inherit (release) tag version;

  src = fetchurl {
    inherit (release.sources."x86_64-linux") hash url;
  };

  contents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # LM Studio downloads the ROCm BLAS libraries separately from the engine
  # extension.  The engine is launched as a child process, so expose that
  # per-user vendor directory inside the FHS environment.  Its bundled
  # libraries also depend on libelf and zstd, which are not part of the
  # default AppImage environment.
  extraPkgs = pkgs: with pkgs; [
    elfutils
    zstd
  ];

  profile = ''
    export LD_LIBRARY_PATH="''${HOME}/.lmstudio/extensions/backends/vendor/linux-llama-rocm-vendor-v4:/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  # The runtime hardware survey launches a helper with a sanitized
  # environment on some LM Studio versions.  Make the downloaded ROCm
  # libraries visible through the normal FHS linker path as well.
  extraPreBwrapCmds = ''
    lmstudio_rocm_vendor="''${HOME}/.lmstudio/extensions/backends/vendor/linux-llama-rocm-vendor-v4"
    lmstudio_rocm_mounts=()
    for library in "$lmstudio_rocm_vendor"/lib*.so*; do
      [ -e "$library" ] || continue
      lmstudio_rocm_mounts+=(--ro-bind-try "$library" "/usr/lib/''${library##*/}")
    done
  '';

  extraBwrapArgs = [
    "\${lmstudio_rocm_mounts[@]}"
  ];

  extraInstallCommands = ''
    mkdir -p "$out/share/applications"

    desktop_entry="$(find ${contents} -type f -name '*.desktop' -print -quit)"
    if [ -n "$desktop_entry" ]; then
      install -m 444 "$desktop_entry" "$out/share/applications/lmstudio.desktop"
      substituteInPlace "$out/share/applications/lmstudio.desktop" \
        --replace-fail 'Exec=AppRun' 'Exec=lmstudio'
    fi
  '';

  meta = {
    description = "Desktop application for running large language models locally";
    homepage = "https://lmstudio.ai";
    downloadPage = "https://lmstudio.ai/download";
    changelog = "https://lmstudio.ai/blog/${tag}";
    license = lib.licenses.unfree;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}

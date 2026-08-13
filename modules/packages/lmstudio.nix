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

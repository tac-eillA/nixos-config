{ appimageTools
, fetchurl
, lib
, stdenv
,
}:

let
  appimageVersions = builtins.fromJSON (builtins.readFile ./appimage-versions.json);
  release = appimageVersions.helium;
  pname = "helium";
  inherit (release) tag version;

  sources = lib.mapAttrs (_: source: fetchurl {
    inherit (source) hash url;
  }) release.sources;

  src = sources.${stdenv.hostPlatform.system};
  contents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    mkdir -p "$out/share/applications" "$out/share/lib/helium"

    cp -r ${contents}/opt/helium/locales "$out/share/lib/helium"
    cp -r ${contents}/usr/share/* "$out/share"
    cp ${contents}/helium.desktop "$out/share/applications/"
  '';

  meta = {
    description = "Private, fast, and honest web browser based on Chromium";
    homepage = "https://helium.computer";
    changelog = "https://github.com/imputnet/helium-linux/releases/tag/${tag}";
    license = lib.licenses.gpl3;
    mainProgram = "helium";
    platforms = builtins.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}

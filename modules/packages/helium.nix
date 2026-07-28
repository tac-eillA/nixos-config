{ appimageTools
, fetchurl
, lib
, stdenv
,
}:

let
  pname = "helium";
  version = "0.14.9.1";

  sources = {
    x86_64-linux = fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
      hash = "sha256-cuQiMGhOPjE7ixuZiFGpRuGF9SdVcNPYUXSXhjZBLKQ=";
    };

    aarch64-linux = fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-arm64.AppImage";
      hash = "sha256-vK5WcsRCDFnW/AzNEMefnJmhvyP5ou1rrtZhgBiwVdQ=";
    };
  };

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
    changelog = "https://github.com/imputnet/helium-linux/releases/tag/${version}";
    license = lib.licenses.gpl3;
    mainProgram = "helium";
    platforms = builtins.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}

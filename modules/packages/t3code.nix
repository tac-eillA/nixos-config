{ appimageTools
, fetchurl
, lib
,
}:

let
  pname = "t3code";
  version = "0.0.31";

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha256-AqTkoSKeQwmql3L9F5SbD1XyqeFyqe11ciq9Tp04Zyw=";
  };

  contents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    mkdir -p "$out/share/applications"
    cp -r ${contents}/usr/share/* "$out/share/"
    install -m 444 ${contents}/t3code.desktop "$out/share/applications/t3code.desktop"
    substituteInPlace "$out/share/applications/t3code.desktop" \
      --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=t3code --no-sandbox %U"
  '';

  meta = {
    description = "Minimal web GUI for coding agents";
    homepage = "https://t3.codes";
    downloadPage = "https://t3.codes/download";
    changelog = "https://github.com/pingdotgg/t3code/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "t3code";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}

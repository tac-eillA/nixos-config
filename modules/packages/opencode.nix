{ fetchurl
, glibc
, lib
, makeWrapper
, ripgrep
, stdenvNoCC
,
}:

let
  appimageVersions = builtins.fromJSON (builtins.readFile ./appimage-versions.json);
  release = appimageVersions.opencode;
  source = release.sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "opencode";
  inherit (release) version;

  src = fetchurl {
    inherit (source) hash url;
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 opencode "$out/libexec/opencode"
    makeWrapper "${glibc}/lib/ld-linux-x86-64.so.2" "$out/bin/opencode" \
      --add-flags "$out/libexec/opencode" \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]} \
      --set OPENCODE_DISABLE_AUTOUPDATE true
    runHook postInstall
  '';

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://opencode.ai";
    changelog = "https://github.com/anomalyco/opencode/releases/tag/${release.tag}";
    license = lib.licenses.mit;
    mainProgram = "opencode";
    platforms = builtins.attrNames release.sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}

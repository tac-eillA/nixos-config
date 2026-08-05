{ fetchurl
, lib
, stdenvNoCC
,
}:

let
  appimageVersions = builtins.fromJSON (builtins.readFile ./appimage-versions.json);
  release = appimageVersions.codex;
  source = release.sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit (release) version;

  src = fetchurl {
    inherit (source) hash url;
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 codex-x86_64-unknown-linux-musl "$out/bin/codex"
    runHook postInstall
  '';

  meta = {
    description = "Lightweight coding agent that runs in a terminal";
    homepage = "https://developers.openai.com/codex/cli";
    changelog = "https://github.com/openai/codex/releases/tag/${release.tag}";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = builtins.attrNames release.sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}

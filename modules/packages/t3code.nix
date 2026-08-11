{ appimageTools
, fetchurl
, lib
, makeWrapper
, symlinkJoin
,
}:

let
  appimageVersions = builtins.fromJSON (builtins.readFile ./appimage-versions.json);
  release = appimageVersions.t3code;
  source = release.sources."x86_64-linux";
  pname = "t3code";
  inherit (release) tag version;

  src = fetchurl {
    inherit (source) hash url;
  };

  contents = appimageTools.extractType2 {
    inherit pname version src;
  };

  meta = {
    description = "Minimal web GUI for coding agents";
    homepage = "https://t3.codes";
    downloadPage = "https://t3.codes/download";
    changelog = "https://github.com/pingdotgg/t3code/releases/tag/${tag}";
    license = lib.licenses.mit;
    mainProgram = "t3code";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };

  appimage = appimageTools.wrapType2 {
    inherit pname version src meta;

    extraInstallCommands = ''
      mkdir -p "$out/share/applications"
      cp -r ${contents}/usr/share/* "$out/share/"
      install -m 444 ${contents}/t3code.desktop "$out/share/applications/t3code.desktop"
      substituteInPlace "$out/share/applications/t3code.desktop" \
        --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=t3code --no-sandbox %U"
    '';
  };
in
symlinkJoin {
  inherit pname version meta;

  paths = [ appimage ];
  nativeBuildInputs = [ makeWrapper ];

  # Hyprland is not one of Electron's auto-detected Linux keyring desktops.
  # Select the GNOME Keyring backend explicitly so Clerk tokens use the
  # workstation's existing Secret Service rather than plaintext storage.
  postBuild = ''
    wrapProgram "$out/bin/t3code" \
      --add-flags "--password-store=gnome-libsecret"

    # The AppImage bundles the current headless CLI inside its ASAR. Run that
    # entry point with Electron's Node mode instead of starting the GUI.
    makeWrapper "$out/bin/.t3code-wrapped" "$out/bin/t3" \
      --set ELECTRON_RUN_AS_NODE 1 \
      --add-flags "${contents}/resources/app.asar/apps/server/dist/bin.mjs"
  '';
}

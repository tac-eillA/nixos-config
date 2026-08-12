{ appimageTools
, fetchurl
, lib
, makeWrapper
, symlinkJoin
, nightly ? false
,
}:

let
  appimageVersions = builtins.fromJSON (builtins.readFile ./appimage-versions.json);
  # Keep upstream's shared application identity; only the Nix-facing names
  # differ so both channels can be installed at once.
  pname = if nightly then "t3code-nightly" else "t3code";
  cliName = if nightly then "t3-nightly" else "t3";
  desktopEntryName = "${pname}.desktop";
  release = appimageVersions.${pname};
  source = release.sources."x86_64-linux";
  inherit (release) tag version;

  src = fetchurl {
    inherit (source) hash url;
  };

  contents = appimageTools.extract {
    inherit pname version src;
  };

  meta = {
    description = "Minimal web GUI for coding agents";
    homepage = "https://t3.codes";
    downloadPage = "https://t3.codes/download";
    changelog = "https://github.com/pingdotgg/t3code/releases/tag/${tag}";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };

  appimage = appimageTools.wrapType2 {
    inherit pname version src meta;

    extraInstallCommands = ''
      mkdir -p "$out/share/applications"
      cp -r ${contents}/usr/share/* "$out/share/"
      install -m 444 ${contents}/t3code.desktop "$out/share/applications/${desktopEntryName}"
      substituteInPlace "$out/share/applications/${desktopEntryName}" \
        --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=${pname} --no-sandbox %U"

      ${lib.optionalString nightly ''
        chmod -R u+w "$out/share/icons"
        find "$out/share/icons" -type f -name t3code.png | while read -r icon; do
          iconDirectory="''${icon%/*}"
          mv -- "$icon" "$iconDirectory/${pname}.png"
        done
        substituteInPlace "$out/share/applications/${desktopEntryName}" \
          --replace-fail "Icon=t3code" "Icon=${pname}"
      ''}
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
  # Releases are pinned by update-appimages because the Nix store is immutable.
  postBuild = ''
    wrapProgram "$out/bin/${pname}" \
      --set T3CODE_DISABLE_AUTO_UPDATE true \
      --add-flags "--password-store=gnome-libsecret"

    # The AppImage bundles the current headless CLI inside its ASAR. Run that
    # entry point with Electron's Node mode instead of starting the GUI.
    makeWrapper "$out/bin/.${pname}-wrapped" "$out/bin/${cliName}" \
      --set ELECTRON_RUN_AS_NODE 1 \
      --add-flags "${contents}/resources/app.asar/apps/server/dist/bin.mjs"
  '';
}

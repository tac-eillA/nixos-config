{ lib, pkgs, ... }:

let
  wallpaper = ../../../img/wallpaper/oilPainting.jpg;
  wallpaperPath = toString wallpaper;
  kwriteconfig = "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6";
  busctl = "${pkgs.systemd}/bin/busctl";
  applyPlasmaWallpaper = pkgs.writeShellScript "apply-plasma-wallpaper" ''
    config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
    lockscreen_config="$config_home/kscreenlockerrc"

    ${kwriteconfig} \
      --file "$lockscreen_config" \
      --group Greeter \
      --group Wallpaper \
      --group org.kde.image \
      --group General \
      --key Image \
      "${wallpaperPath}"

    ${kwriteconfig} \
      --file "$lockscreen_config" \
      --group Greeter \
      --group Wallpaper \
      --group org.kde.image \
      --group General \
      --key PreviewImage \
      "${wallpaperPath}"

    for _ in $(${pkgs.coreutils}/bin/seq 1 10); do
      if ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage "${wallpaperPath}" >/dev/null 2>&1; then
        break
      fi

      ${pkgs.coreutils}/bin/sleep 2
    done
  '';
  applyPlasmaTilingShortcuts = pkgs.writeShellScript "apply-plasma-tiling-shortcuts" ''
    config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
    kwin_config="$config_home/kwinrc"
    global_shortcuts_config="$config_home/kglobalshortcutsrc"

    write_kwin() {
      ${kwriteconfig} --file "$kwin_config" "$@"
    }

    write_shortcut() {
      ${kwriteconfig} --file "$global_shortcuts_config" "$@"
    }

    write_kwin --group Desktops --key Number 5
    write_kwin --group Desktops --key Rows 1

    for desktop in $(${pkgs.coreutils}/bin/seq 1 5); do
      write_shortcut \
        --group kwin \
        --key "Switch to Desktop $desktop" \
        "Meta+$desktop,Meta+$desktop,Switch to Desktop $desktop"

      write_shortcut \
        --group kwin \
        --key "Window to Desktop $desktop" \
        "Meta+Shift+$desktop,Meta+Shift+$desktop,Window to Desktop $desktop"

      write_shortcut \
        --group plasmashell \
        --key "activate task manager entry $desktop" \
        ",,Activate Task Manager Entry $desktop"
    done

    write_shortcut --group kwin --key "Window Maximize" \
      "Meta+Up,Meta+Up,Maximize Window"
    write_shortcut --group kwin --key "Window Quick Tile Top" \
      ",,Quick Tile Window to the Top"
    write_shortcut --group kwin --key "Window Close" \
      "Meta+Q\tAlt+F4,Alt+F4,Close Window"

    write_shortcut --group ActivityManager --key "manage activities" \
      ",,Show Activity Switcher"

    write_shortcut --group kwin --key "Switch Window Left" \
      "Meta+Alt+H,Meta+Alt+H,Switch to Window to the Left"
    write_shortcut --group kwin --key "Switch Window Down" \
      "Meta+Alt+J,Meta+Alt+J,Switch to Window Below"
    write_shortcut --group kwin --key "Switch Window Up" \
      "Meta+Alt+K,Meta+Alt+K,Switch to Window Above"
    write_shortcut --group kwin --key "Switch Window Right" \
      "Meta+Alt+L,Meta+Alt+L,Switch to Window to the Right"

    write_shortcut --group kwin --key "Window Pack Left" \
      "Meta+Shift+H,Meta+Shift+H,Move Window Left"
    write_shortcut --group kwin --key "Window Pack Down" \
      "Meta+Shift+J,Meta+Shift+J,Move Window Down"
    write_shortcut --group kwin --key "Window Pack Up" \
      "Meta+Shift+K,Meta+Shift+K,Move Window Up"
    write_shortcut --group kwin --key "Window Pack Right" \
      "Meta+Shift+L,Meta+Shift+L,Move Window Right"

    if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
      ${busctl} --user call org.kde.KWin /KWin org.kde.KWin reconfigure >/dev/null 2>&1 || true
      ${busctl} --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel reloadConfig >/dev/null 2>&1 || true
    fi
  '';
in
{
  home.activation.applyPlasmaTilingShortcuts =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${applyPlasmaTilingShortcuts}
    '';

  xdg.configFile."autostart/org.allison.apply-plasma-wallpaper.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Apply Plasma Wallpaper
    Exec=${applyPlasmaWallpaper}
    OnlyShowIn=KDE;
    X-KDE-autostart-phase=1
    NoDisplay=true
  '';

  xdg.configFile."autostart/org.allison.apply-plasma-tiling-shortcuts.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Apply Plasma Tiling Shortcuts
    Exec=${applyPlasmaTilingShortcuts}
    OnlyShowIn=KDE;
    X-KDE-autostart-phase=1
    NoDisplay=true
  '';
}

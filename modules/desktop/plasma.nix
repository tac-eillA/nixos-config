{ pkgs, ... }:

let
  wallpaper = ../../img/wallpaper/oilPainting.jpg;
  wallpaperPath = toString wallpaper;
  applyWallpaper = pkgs.writeShellScript "apply-plasma-wallpaper" ''
    config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
    lockscreen_config="$config_home/kscreenlockerrc"

    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file "$lockscreen_config" \
      --group Greeter \
      --group Wallpaper \
      --group org.kde.image \
      --group General \
      --key Image \
      "${wallpaperPath}"

    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
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
in
{
  services.xserver.enable = true;
  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.etc."xdg/autostart/org.allison.apply-plasma-wallpaper.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Apply Plasma Wallpaper
    Exec=${applyWallpaper}
    OnlyShowIn=KDE;
    X-KDE-autostart-phase=1
    NoDisplay=true
  '';

  xdg.portal.enable = true;
  xdg.portal.xdgOpenUsePortal = true;

  services.power-profiles-daemon.enable = true;

  programs.kdeconnect.enable = true;

  # Trim a few bundled Plasma apps.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    plasma-browser-integration
  ];

  environment.systemPackages = with pkgs; [
    kdePackages.kate
    kdePackages.filelight
    kdePackages.partitionmanager
  ];
}

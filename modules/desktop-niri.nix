{ pkgs, ... }:
{
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --cmd niri-session";
      };
    };
  };

  services.gnome.gnome-keyring.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  services.libinput.enable = true;
  security.pam.services.swaylock = { };

  environment.systemPackages = with pkgs; [
    niri
    waybar
    wofi
    mako
    swayidle
    swaylock
    swww
    grim
    slurp
    wl-clipboard
    lxqt.lxqt-policykit
    networkmanagerapplet
    blueman
    brightnessctl
    playerctl
  ];

  environment.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
  };
}

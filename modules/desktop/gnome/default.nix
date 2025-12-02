{ lib, pkgs, ... }:
{
  imports = [
    ./dconf.nix
    ../../themes/Catppuccin
  ];
  services = {
    desktopManager.gnome.enable = true;
    gnome.gnome-initial-setup.enable = false;
    gnome.games.enable = false;
    power-profiles-daemon.enable = false;
    #tlp.enable = lib.mkForce true; # gnome has builtin power management
    xserver = {
      enable = true;
      #layout = "gb";
      #libinput = { touchpad.tapping = true; };
    };
  };

  environment.gnome.excludePackages = with pkgs; [
    #gnome-backgrounds
    #pkgs.gnome-video-effects
    gnome-maps
    gnome-music
    gnome-tour
    gnome-text-editor
    gnome-user-docs
    gnome-contacts
    gnome-initial-setup
    geary
    gedit
    epiphany
    cheese
  ];
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.vitals
    gnomeExtensions.arcmenu
    # gnomeExtensions.appindicator
    # gnomeExtensions.blur-my-shell
    # gnomeExtensions.burn-my-windows
    # gnomeExtensions.compact-top-bar
    # gnomeExtensions.custom-accent-colors
    # gradience
    # gnomeExtensions.gtile
    # gnomeExtensions.dash-to-panel
    # gnomeExtensions.tray-icons-reloaded
    SgnomeExtensions.paperwm
    # gnomeExtensions.just-perfection
  ];
}

{ pkgs, vars, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    warn-dirty = false;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = vars.locale.timeZone or "UTC";

  i18n.defaultLocale = vars.locale.defaultLocale or "en_US.UTF-8";
  console.keyMap = vars.locale.keyMap or "us";

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    histSize = 20000;
    shellAliases = {
      ll = "eza -al --group-directories-first --icons=auto";
      ls = "eza --group-directories-first --icons=auto";
      la = "eza -a --group-directories-first --icons=auto";
      cat = "bat --paging=never";
      v = "nvim";
      g = "git";
    };
  };
  users.defaultUserShell = pkgs.zsh;

  environment.etc."zshenv".text = ''
    export ZDOTDIR="$HOME/.config/zsh"
  '';

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    EDITOR = "nvim";
    TERMINAL = "kitty";
    BROWSER = "firefox";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    GTK_THEME = "adw-gtk3-dark";
  };
}

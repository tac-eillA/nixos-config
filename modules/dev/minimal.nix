{ pkgs, ... }:

{
  imports = [ ./git.nix ];

  environment.systemPackages = with pkgs; [
    gh
    bash
    curl
    wget
    which
    ghostty
    neovim
    openssl
    libargon2
    mosh
    tmux
    tailscale
  ];

  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };

  environment.etc."xdg/ghostty/config".text = ''
    # Catppuccin Mocha OLED
    background = #000000
    foreground = #cdd6f4
    cursor-color = #f5e0dc
    cursor-text = #000000
    selection-background = #45475a
    selection-foreground = #cdd6f4

    palette = 0=#000000
    palette = 1=#f38ba8
    palette = 2=#a6e3a1
    palette = 3=#f9e2af
    palette = 4=#89b4fa
    palette = 5=#f5c2e7
    palette = 6=#94e2d5
    palette = 7=#bac2de
    palette = 8=#585b70
    palette = 9=#f38ba8
    palette = 10=#a6e3a1
    palette = 11=#f9e2af
    palette = 12=#89b4fa
    palette = 13=#f5c2e7
    palette = 14=#94e2d5
    palette = 15=#cdd6f4

    window-padding-x = 10
    window-padding-y = 8
    window-padding-balance = true
    background-opacity = 1
  '';
}

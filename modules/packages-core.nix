{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    inter
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    font-awesome
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Inter" "Noto Sans" ];
    monospace = [ "JetBrainsMono Nerd Font" ];
    emoji = [ "Noto Color Emoji" ];
  };

  environment.systemPackages = with pkgs; [
    adw-gtk3
    bibata-cursors

    kitty
    firefox
    google-chrome
    emacs
    nautilus
    file-roller
    pavucontrol

    git
    gh
    opencode
    wget
    curl
    unzip
    zip
    p7zip

    neovim
    tmux
    ripgrep
    fd
    fzf
    eza
    bat
    zoxide
    lazygit
    tree
    btop
    fastfetch

    lua-language-server
    stylua
    nixd
  ];
}

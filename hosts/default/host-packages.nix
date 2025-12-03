{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    obsidian
    blender
    krita
    godot
    neovim
    gh
    zed-editor
    google-chrome
    ghostty
    python314
    pciutils
    cider-2
    streamrip
    vial
    davinci-resolve
    emacs
  ];
}

{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    obsidian
    blender
    krita
    godot
    neovim
    gh
    code-cursor-fhs
    zed-editor
    google-chrome
    ghostty
    python314
    pciutils
    cider-2
  ];
}

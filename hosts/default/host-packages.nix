{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    obsidian
    blender
    krita
    godot
    neovim
    gh
    code-cursor
    code-cursor-fhs
    ghostty
    python314
  ];
}

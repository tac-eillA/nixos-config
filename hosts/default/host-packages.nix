{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    obsidian
    blender
    krita
    godot
    neovim
  ];
}

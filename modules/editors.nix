{ pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    emacs
    neovim
    jetbrains.rider
    jetbrains.clion
    jetbrains.rust-rover
    zed-editor-fhs
  ];
}

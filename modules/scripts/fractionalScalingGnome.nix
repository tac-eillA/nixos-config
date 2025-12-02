{
  pkgs,
  lib,
  ...
}:
let
in
pkgs.writeShellScriptBin "fractionalScalingGnome" ''
  $gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
''

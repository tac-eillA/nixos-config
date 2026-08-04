{ ... }:

let
  logo = ../../../img/readme/nixos-logo.png;
in
{
  xdg.configFile."hyfetch.json".text = builtins.toJSON {
    preset = "transgender";
    mode = "rgb";
    auto_detect_light_dark = true;
    light_dark = "dark";
    lightness = 0.65;
    color_align = {
      mode = "horizontal";
    };
    backend = "neofetch";
    args = "--backend kitty --source ${toString logo} --image_size 20%";
    distro = "nixos";
    pride_month_disable = false;
    custom_ascii_path = null;
  };
}

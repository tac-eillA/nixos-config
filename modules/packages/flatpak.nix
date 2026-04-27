{ ... }:

{
  services = {
    flatpak = {
      enable = true;

      # Add Flatpak IDs here when you want declarative installs.
      # packages = [ "com.github.tchx84.Flatseal" ];
      # update.onActivation = true;
    };
  };
}

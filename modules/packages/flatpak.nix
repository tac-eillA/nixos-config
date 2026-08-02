{ ... }:

{
  services = {
    flatpak = {
      enable = true;

      packages = [ "com.bitwarden.desktop" ];
    };
  };
}

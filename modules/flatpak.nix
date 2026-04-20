{ inputs, ... }:
{
  #imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
  services = {
    flatpak = {
      enable = true;

      # List the Flatpak applications you want to install
      # Use the official Flatpak application ID (e.g., from flathub.org)
      packages = [
        "com.github.tchx84.Flatseal"      # Manage flatpak permissions - should always have this
        "io.github.flattool.Warehouse"    # Manage flatpaks, clean data, remove flatpaks and deps
        "app.opencomic.OpenComic"         # Comic and Manga reader
        "com.discordapp.Discord"
        "com.core447.StreamController"

        # Add other Flatpak IDs here, e.g., "org.mozilla.firefox"
      ];

      # Optional: Automatically update Flatpaks when you run nixos-rebuild swit ch
      update.onActivation = true;
    };
  };
}

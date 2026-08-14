{ ... }:

{
  services = {
    flatpak = {
      enable = true;

      packages = [
        "com.bitwarden.desktop"
        "org.blender.Blender"
        "org.godotengine.Godot"
        "org.kicad.KiCad"
        "org.kde.krita"
        "com.obsproject.Studio"
        "org.qbittorrent.qBittorrent"
        "com.github.johnfactotum.Foliate"
        "com.github.wwmm.easyeffects"
        "com.calibre_ebook.calibre"
        "io.mpv.Mpv"
        "org.libreoffice.LibreOffice"
        "com.moonlight_stream.Moonlight"
      ];
    };
  };
}

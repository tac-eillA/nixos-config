{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    preferences = {
      "browser.tabs.unloadOnLowMemory" = true;
      "dom.ipc.processCount" = 6;
    };
  };

  # environment.systemPackages = with pkgs; [
  #   nur.repos.lonerOrz.helium
  # ];
}


{
  pkgs,
  inputs,
  host,
  ...
}:
let
  inherit (import ../../../hosts/${host}/variables.nix)
    username
    editor
    terminal
    browser
    shell
    ;
in
{

    home-manager.users.allison = {
      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      xdg.enable = true;
      home = {
        username = "allison";
        homeDirectory = "/home/allison";
        stateVersion = "25.05"; # Do not change!
        sessionVariables = {
          EDITOR = "emacs";
          BROWSER = "${browser}";
          TERMINAL = "${terminal}";
        };
      };
    };

  users = {
    users.allison = {
      isNormalUser = true;
      extraGroups = [
        "wheel" # sudo access
        "input"
        "networkmanager"
        "video"
        "audio"
        "libvirtd" #Virt manager/QEMU access
        "kvm"
        "docker" #access to docker as non-root
        "disk"
        "adbusers"
        "lp"
        "scanner"
        "vboxusers" # Virtual Box
      ];
      shell = pkgs.${shell};
      ignoreShellProgramCheck = true;
    };
  };
}

{ config, doomEmacs, pkgs, ... }:

{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
    extraPackages = epkgs: [ epkgs.vterm ];
  };

  xdg.configFile = {
    emacs.source = doomEmacs;
    "doom/init.el".source = ./doom/init.el;
    "doom/config.el".source = ./doom/config.el;
    "doom/packages.el".source = ./doom/packages.el;
  };

  home = {
    sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];
    packages = with pkgs; [
      ripgrep
      fd
      (aspellWithDicts (dicts: [
        dicts.en
        dicts.en-computers
      ]))
      nixfmt
      nixd
      go
      gopls
      gotools
      rustc
      cargo
      rust-analyzer
      rustfmt
      clang
      clang-tools
      cmake
      gnumake
      gdb
    ];
  };
}

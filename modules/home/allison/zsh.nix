{ ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=#585b70";
    };
    syntaxHighlighting = {
      enable = true;
      styles = {
        default = "fg=#cdd6f4";
        unknown-token = "fg=#f38ba8,bold";
        reserved-word = "fg=#cba6f7";
        alias = "fg=#89b4fa";
        builtin = "fg=#89b4fa";
        function = "fg=#89b4fa";
        command = "fg=#89b4fa";
        precommand = "fg=#94e2d5";
        path = "fg=#a6e3a1,underline";
        path_pathseparator = "fg=#45475a";
        globbing = "fg=#f9e2af";
        history-expansion = "fg=#f9e2af";
        single-hyphen-option = "fg=#fab387";
        double-hyphen-option = "fg=#fab387";
        single-quoted-argument = "fg=#a6e3a1";
        double-quoted-argument = "fg=#a6e3a1";
        dollar-quoted-argument = "fg=#a6e3a1";
        dollar-double-quoted-argument = "fg=#f5c2e7";
        back-double-quoted-argument = "fg=#f5c2e7";
        back-quoted-argument = "fg=#f5c2e7";
        assign = "fg=#f5c2e7";
        redirection = "fg=#f5c2e7";
        comment = "fg=#6c7086";
      };
    };
    shellAliases = {
      ll = "ls -lah";
      la = "ls -A";
      l = "ls -CF";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      nixc = "cd ~/nixos-config";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)";
      rebuild-boot = "sudo nixos-rebuild boot --flake ~/nixos-config#$(hostname)";
      update = "nix flake update --flake ~/nixos-config";
      garbage = "sudo nix-collect-garbage -d";
      c = "clear";
    };
    initContent = ''
      bindkey -e
      autoload -Uz colors && colors
      PS1="%F{#89b4fa}%n@%m%f:%F{#a6e3a1}%~%f %F{#f5c2e7}%#%f "
    '';
  };
}

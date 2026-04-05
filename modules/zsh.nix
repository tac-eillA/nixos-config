# modules/zsh.nix
{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "ls -lah";
      la = "ls -A";
      l = "ls -CF";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)";
      update = "nix flake update ~/nixos-config";
      c = "clear";
    };

    interactiveShellInit = ''
      bindkey -e
      export EDITOR=nvim
      export VISUAL=nvim
    '';

    promptInit = ''
      autoload -Uz colors && colors
      PS1="%F{blue}%n@%m%f:%F{green}%~%f %# "
    '';
  };

  environment.systemPackages = with pkgs; [
    zsh
  ];
}

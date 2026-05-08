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
      nixc = "cd ~/nixos-config";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)";
      rebuild-boot = "sudo nixos-rebuild boot --flake ~/nixos-config#$(hostname)";
      update = "nix flake update --flake ~/nixos-config";
      garbage = "sudo nix-collect-garbage -d";
      c = "clear";
    };

    interactiveShellInit = ''
      bindkey -e
      export EDITOR=nvim
      export VISUAL=nvim

      # Catppuccin Mocha OLED shell colors.
      export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70"
      typeset -gA ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES[default]="fg=#cdd6f4"
      ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#f38ba8,bold"
      ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#cba6f7"
      ZSH_HIGHLIGHT_STYLES[alias]="fg=#89b4fa"
      ZSH_HIGHLIGHT_STYLES[builtin]="fg=#89b4fa"
      ZSH_HIGHLIGHT_STYLES[function]="fg=#89b4fa"
      ZSH_HIGHLIGHT_STYLES[command]="fg=#89b4fa"
      ZSH_HIGHLIGHT_STYLES[precommand]="fg=#94e2d5"
      ZSH_HIGHLIGHT_STYLES[path]="fg=#a6e3a1,underline"
      ZSH_HIGHLIGHT_STYLES[path_pathseparator]="fg=#45475a"
      ZSH_HIGHLIGHT_STYLES[globbing]="fg=#f9e2af"
      ZSH_HIGHLIGHT_STYLES[history-expansion]="fg=#f9e2af"
      ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=#fab387"
      ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=#fab387"
      ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#a6e3a1"
      ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#a6e3a1"
      ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#a6e3a1"
      ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]="fg=#f5c2e7"
      ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]="fg=#f5c2e7"
      ZSH_HIGHLIGHT_STYLES[back-quoted-argument]="fg=#f5c2e7"
      ZSH_HIGHLIGHT_STYLES[assign]="fg=#f5c2e7"
      ZSH_HIGHLIGHT_STYLES[redirection]="fg=#f5c2e7"
      ZSH_HIGHLIGHT_STYLES[comment]="fg=#6c7086"
    '';

    promptInit = ''
      autoload -Uz colors && colors
      PS1="%F{#89b4fa}%n@%m%f:%F{#a6e3a1}%~%f %F{#f5c2e7}%#%f "
    '';
  };

  environment.systemPackages = with pkgs; [
    zsh
  ];
}

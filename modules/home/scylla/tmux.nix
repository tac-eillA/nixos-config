{ ... }:

{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 10;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";

    extraConfig = ''
      set -g renumber-windows on
      set -g allow-passthrough on
      set -as terminal-overrides ",xterm-256color:RGB,tmux-256color:RGB"

      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded"
      bind | split-window -h
      bind - split-window -v

      set -g status-style "bg=#000000,fg=#cdd6f4"
      set -g status-left "#[fg=#89b4fa,bold] #S "
      set -g status-right "#[fg=#a6e3a1]%H:%M "
      set -g window-status-current-format "#[fg=#000000,bg=#89b4fa,bold] #I:#W "
      set -g window-status-format "#[fg=#585b70] #I:#W "
      set -g pane-border-style "fg=#313244"
      set -g pane-active-border-style "fg=#89b4fa"
    '';
  };
}

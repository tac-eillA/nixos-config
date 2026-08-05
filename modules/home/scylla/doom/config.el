;;; config.el -*- lexical-binding: t; -*-

(setq user-full-name "Allison Snodgrass"
      doom-theme 'catppuccin
      catppuccin-flavor 'mocha
      doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 14)
      doom-variable-pitch-font (font-spec :family "Noto Sans" :size 14)
      display-line-numbers-type 'relative
      tab-width 2
      standard-indent 2
      indent-tabs-mode nil
      auto-save-default t
      confirm-kill-emacs nil)

(after! catppuccin-theme
  (custom-set-faces!
    '(default :background "#000000" :foreground "#cdd6f4")
    '(fringe :background "#000000")
    '(line-number :background "#000000" :foreground "#585b70")
    '(line-number-current-line :background "#11111b" :foreground "#f9e2af" :weight bold)))

(after! lsp-mode
  (setq lsp-nix-nixd-server-path "nixd"
        lsp-nix-nixd-formatting-command [ "nixfmt" ]
        lsp-rust-analyzer-server-command '("rust-analyzer")
        lsp-go-gopls-server-path "gopls"
        lsp-clients-clangd-executable "clangd"))

(add-hook! '(prog-mode-hook text-mode-hook)
  (setq-local indent-tabs-mode nil
              tab-width 2))

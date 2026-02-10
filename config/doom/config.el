;;; config.el -*- lexical-binding: t; -*-

(setq user-full-name "Allison"
      user-mail-address "allison@example.com")

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 13)
      doom-variable-pitch-font (font-spec :family "Inter" :size 13)
      doom-big-font (font-spec :family "JetBrainsMono Nerd Font" :size 20))

(setq doom-theme 'doom-one)
(setq display-line-numbers-type 'relative)

(setq org-directory "~/org/")

(after! doom-modeline
  (setq doom-modeline-height 28
        doom-modeline-bar-width 4))

(after! treemacs
  (setq treemacs-width 34))

(map! :leader
      :desc "Find file" "f f" #'find-file
      :desc "Recent files" "f r" #'consult-recent-file
      :desc "Format buffer" "c f" #'+format/buffer)

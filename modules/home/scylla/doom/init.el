;;; init.el -*- lexical-binding: t; -*-

(doom! :completion
       (corfu +icons +orderless)
       vertico

       :ui
       doom
       dashboard
       doom-quit
       hl-todo
       modeline
       ophints
       (popup +defaults)
       (vc-gutter +pretty)
       vi-tilde-fringe
       window-select
       workspaces

       :editor
       (evil +everywhere)
       file-templates
       fold
       (format +onsave)
       snippets

       :emacs
       dired
       electric
       undo
       vc

       :term
       vterm

       :checkers
       syntax

       :tools
       (eval +overlay)
       lookup
       lsp
       magit
       make
       tree-sitter

       :lang
       (cc +lsp +tree-sitter)
       emacs-lisp
       (go +lsp +tree-sitter)
       json
       markdown
       (nix +lsp +tree-sitter)
       org
       (rust +lsp +tree-sitter)
       sh
       yaml

       :config
       default)

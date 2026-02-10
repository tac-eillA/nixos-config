;;; init.el -*- lexical-binding: t; -*-

(doom!
 :input
 layout

 :completion
 (company +childframe)
 vertico

 :ui
 doom
 doom-dashboard
 hl-todo
 modeline
 ophints
 (popup +defaults)
 treemacs
 vc-gutter
 vi-tilde-fringe
 workspaces

 :editor
 (evil +everywhere)
 file-templates
 fold
 format
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
 tree-sitter

 :os
 tty

 :lang
 emacs-lisp
 json
 javascript
 markdown
 nix
 org
 python
 rust
 sh
 web
 yaml

 :config
 (default +bindings +smartparens))

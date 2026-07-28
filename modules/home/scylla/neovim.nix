{ ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    initLua = ''
      vim.g.mapleader = " "

      local opt = vim.opt
      opt.number = true
      opt.relativenumber = true
      opt.termguicolors = true
      opt.cursorline = true
      opt.expandtab = true
      opt.shiftwidth = 2
      opt.tabstop = 2
      opt.ignorecase = true
      opt.smartcase = true
      opt.clipboard = "unnamedplus"

      vim.cmd([[
        highlight clear
        syntax reset
        set background=dark
        let g:colors_name = "oled"

        highlight Normal guibg=#000000 guifg=#cdd6f4
        highlight NormalNC guibg=#000000 guifg=#cdd6f4
        highlight CursorLine guibg=#11111b
        highlight LineNr guibg=#000000 guifg=#585b70
        highlight CursorLineNr guibg=#11111b guifg=#f9e2af gui=bold
        highlight SignColumn guibg=#000000
        highlight Visual guibg=#45475a
        highlight Search guibg=#f9e2af guifg=#000000
        highlight IncSearch guibg=#fab387 guifg=#000000
        highlight Comment guifg=#6c7086 gui=italic
        highlight Constant guifg=#fab387
        highlight String guifg=#a6e3a1
        highlight Identifier guifg=#cdd6f4
        highlight Function guifg=#89b4fa
        highlight Statement guifg=#cba6f7
        highlight Keyword guifg=#cba6f7
        highlight Type guifg=#94e2d5
        highlight PreProc guifg=#f5c2e7
        highlight Special guifg=#f5c2e7
        highlight Error guifg=#f38ba8 guibg=#000000
      ]])

      local map = vim.keymap.set
      map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
      map("n", "<leader>q", "<cmd>nohlsearch<cr>", { desc = "Clear search" })
    '';
  };
}

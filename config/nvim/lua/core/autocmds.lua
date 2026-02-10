local augroup = vim.api.nvim_create_augroup("ArtemisUserConfig", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank({ timeout = 120 })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function(args)
    local line = vim.fn.line("'\"")
    local last = vim.fn.line("$")
    if line > 1 and line <= last then
      pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
    end
  end,
})

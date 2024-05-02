-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.python3_host_prog = "/home/mattniedelman/.asdf/shims/python"
vim.opt.timeoutlen = 100

vim.g.lazyvim_python_lsp = "pyright"

-- for edgy.nvim
vim.opt.splitkeep = "screen"
vim.opt.laststatus = 3

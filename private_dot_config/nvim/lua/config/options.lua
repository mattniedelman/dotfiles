-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH

vim.opt.swapfile = false

-- Auto-reload settings
vim.opt.autoread = true -- Automatically read file when changed outside of vim
vim.opt.updatetime = 250 -- Faster completion and file change detection
vim.opt.confirm = false -- Don't prompt to save/reload, just do it silently

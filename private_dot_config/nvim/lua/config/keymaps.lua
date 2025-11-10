-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("", "q", "<nop>")
vim.keymap.set("", "Q", "<nop>")

vim.cmd([[
  cabbrev <expr> w getcmdtype()==':' && getcmdline() == "'<,'>w" ? '<c-u>w' : 'w'
]])
vim.keymap.set("i", "<C-f>", "<cmd>call augment#Accept()<cr>", { noremap = true, silent = true })

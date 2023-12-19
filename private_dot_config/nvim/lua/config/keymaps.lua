-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set({ "i", "v" }, "fd", "<ESC>", { desc = "Exit chord" })
vim.keymap.set({ "i", "v", "n" }, "<C-a>", "<ESC>^", { desc = "Beginning of line" })
vim.keymap.set({ "i", "v", "n" }, "<C-e>", "<ESC>$", { desc = "End of line" })

vim.keymap.set("", "q", "<nop>")
vim.keymap.set("", "Q", "<nop>")

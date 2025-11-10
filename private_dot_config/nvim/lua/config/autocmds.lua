-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-reload files when they change externally
local auto_reload_group = vim.api.nvim_create_augroup("AutoReload", { clear = true })

-- Check for file changes when entering a buffer or gaining focus
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "CursorHold", "CursorHoldI" }, {
  group = auto_reload_group,
  pattern = "*",
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})

-- Automatically reload file if it has been changed externally
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = auto_reload_group,
  pattern = "*",
  callback = function()
    vim.notify("File changed on disk. Buffer reloaded!", vim.log.levels.WARN)
  end,
})

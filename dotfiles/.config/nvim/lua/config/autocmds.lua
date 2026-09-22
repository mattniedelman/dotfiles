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

-- Check for file changes when entering a buffer or gaining focus.
-- BufEnter + FocusGained cover the real external-change cases (returning to
-- the terminal, switching buffers); CursorHold* would poll the filesystem on
-- every idle pause (up to 4x/sec at updatetime=250) with no added benefit.
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
  group = auto_reload_group,
  pattern = "*",
  callback = function()
    if vim.fn.mode() ~= "c" and vim.bo.buftype == "" then
      vim.cmd("silent! checktime")
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

-- LSP cleanup: Stop orphaned LSP servers when buffers are deleted
local lsp_cleanup_group = vim.api.nvim_create_augroup("LspCleanup", { clear = true })

vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  group = lsp_cleanup_group,
  callback = function(args)
    pcall(function()
      local bufnr = args.buf
      local clients = vim.lsp.get_clients({ bufnr = bufnr }) or {}

      for _, client in ipairs(clients) do
        local other_count = 0
        for buf in pairs(client.attached_buffers or {}) do
          if buf ~= bufnr and vim.api.nvim_buf_is_valid(buf) then
            other_count = other_count + 1
          end
        end

        if other_count == 0 and client and client.id then
          vim.schedule(function()
            pcall(function()
              client:stop(true)
            end)
          end)
        end
      end
    end)
  end,
})

-- Additional cleanup on VimLeavePre to ensure all LSP servers are stopped
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = lsp_cleanup_group,
  callback = function()
    pcall(function()
      -- Clear any pending messages before cleanup
      vim.cmd("silent! messages clear")

      local clients = vim.lsp.get_clients() or {}
      for _, client in ipairs(clients) do
        if client and client.id then
          pcall(function()
            client:stop(true)
          end)
        end
      end
    end)

    -- Clear any error messages generated during cleanup
    vim.cmd("silent! messages clear")
  end,
})

-- Markdown: hard-wrap your typing at 100, soft-wrap any existing long lines for readability
local markdown_wrap_group = vim.api.nvim_create_augroup("MarkdownWrap", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = markdown_wrap_group,
  pattern = { "markdown", "markdown.mdx" },
  callback = function()
    vim.opt_local.textwidth = 100
    vim.opt_local.formatoptions:append("t")
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

-- Disable autoformat for files in /tmp
local disable_autoformat_group = vim.api.nvim_create_augroup("DisableAutoformat", { clear = true })
vim.api.nvim_create_autocmd("BufReadPost", {
  group = disable_autoformat_group,
  pattern = "/tmp/*",
  callback = function()
    vim.b.autoformat = false
  end,
})

require("config.chezmoi")

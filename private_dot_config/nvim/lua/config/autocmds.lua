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


-- LSP cleanup: Stop orphaned LSP servers when buffers are deleted
local lsp_cleanup_group = vim.api.nvim_create_augroup("LspCleanup", { clear = true })

vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  group = lsp_cleanup_group,
  callback = function(args)
    local bufnr = args.buf

    -- Get all LSP clients attached to this buffer
    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    for _, client in ipairs(clients) do
      -- Check if this client is attached to any other buffers
      local attached_buffers = vim.lsp.get_buffers_by_client_id(client.id)
      local other_buffers = vim.tbl_filter(function(buf)
        return buf ~= bufnr and vim.api.nvim_buf_is_valid(buf)
      end, attached_buffers)

      -- If no other valid buffers are attached, stop the client
      if #other_buffers == 0 then
        vim.schedule(function()
          if client and client.id then
            vim.lsp.stop_client(client.id)
          end
        end)
      end
    end
  end,
})

-- Additional cleanup on VimLeavePre to ensure all LSP servers are stopped
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = lsp_cleanup_group,
  callback = function()
    local clients = vim.lsp.get_clients()
    for _, client in ipairs(clients) do
      vim.lsp.stop_client(client.id)
    end
  end,
})

require("config.chezmoi")

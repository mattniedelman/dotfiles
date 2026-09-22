-- Chezmoi integration for Neovim
-- Automatically prompts to edit source file when opening a chezmoi-managed file
--
-- Performance note: chezmoi is a slow external process (~30-75ms per spawn).
-- Every synchronous shell-out on BufRead blocks the UI and makes files slow to
-- open. To keep the hot path fast, all chezmoi calls here are async
-- (vim.system) and gated behind cheap Lua checks so unrelated files never
-- touch chezmoi at all.

local HOME = vim.fn.expand("~")

-- The chezmoi source directory root, resolved once, asynchronously, at
-- startup. Nil until resolved; used only to skip files already in the source
-- tree, so an unresolved value simply means "don't skip" (fail-open).
local source_root = nil

-- Cache for managed target files, keyed by absolute path. Refreshed
-- asynchronously with a TTL. Managed lookups are pure Lua against this table.
local managed_files_cache = {}
local cache_timestamp = 0
local cache_refreshing = false
local CACHE_TTL = 300 -- 5 minutes in seconds

-- Resolve the chezmoi source root once (async, non-blocking).
vim.system({ "chezmoi", "source-path" }, { text = true }, function(out)
  if out.code == 0 then
    local root = vim.trim(out.stdout or "")
    if root ~= "" then
      source_root = root
    end
  end
end)

-- Refresh the managed-files cache in the background. Never blocks; callers use
-- whatever cache is currently populated and let this update it for next time.
local function refresh_managed_cache()
  if cache_refreshing then
    return
  end
  cache_refreshing = true
  vim.system({ "chezmoi", "managed", "--include=all" }, { text = true }, function(out)
    cache_refreshing = false
    if out.code ~= 0 then
      return
    end
    local fresh = {}
    for line in (out.stdout or ""):gmatch("[^\n]+") do
      -- chezmoi managed prints paths relative to the destination (home) dir
      fresh[HOME .. "/" .. line] = true
    end
    managed_files_cache = fresh
    cache_timestamp = os.time()
  end)
end

-- Main autocmd to handle opening chezmoi-managed files.
vim.api.nvim_create_autocmd("BufRead", {
  group = vim.api.nvim_create_augroup("ChezmoiAutoEdit", { clear = true }),
  callback = function()
    local file = vim.fn.expand("%:p")

    -- Cheap Lua guards first -- no external process on the common path.

    -- Skip anything outside the home dir (chezmoi only manages files there).
    if file == "" or file:find(HOME, 1, true) ~= 1 then
      return
    end

    -- Skip files already in the chezmoi source tree.
    if source_root and file:find(source_root, 1, true) == 1 then
      return
    end

    -- Skip if the file doesn't actually exist on disk.
    if vim.fn.filereadable(file) == 0 then
      return
    end

    -- Keep the managed-files cache warm; this is async and never blocks.
    if os.time() - cache_timestamp >= CACHE_TTL then
      refresh_managed_cache()
    end

    -- Pure Lua lookup. If the cache isn't populated yet (first opens after
    -- startup), fail-open: no prompt this time, cache warms for next time.
    if managed_files_cache[file] ~= true then
      return
    end

    -- Confirmed managed. Resolve the source path async, then prompt.
    vim.system({ "chezmoi", "source-path", file }, { text = true }, function(out)
      if out.code ~= 0 then
        return
      end
      local source_file = vim.trim(out.stdout or "")
      if source_file == "" then
        return
      end

      vim.schedule(function()
        local choice =
          vim.fn.confirm("This file is managed by chezmoi.\nEdit source instead?", "&Yes\n&No\n&Always edit target", 1)

        if choice == 1 then
          -- Edit source file
          vim.cmd("edit " .. vim.fn.fnameescape(source_file))
        elseif choice == 3 then
          -- Disable auto-edit for this session
          vim.api.nvim_del_augroup_by_name("ChezmoiAutoEdit")
          vim.notify("Chezmoi auto-edit disabled for this session", vim.log.levels.INFO)
        end
        -- choice == 2 means continue editing target file (do nothing)
      end)
    end)
  end,
})

-- Custom commands for chezmoi operations
vim.api.nvim_create_user_command("ChezmoiEdit", function()
  -- Explicit, user-invoked command: a one-shot synchronous call is fine here
  -- (unlike the per-BufRead hot path, this runs only on demand).
  local file = vim.fn.expand("%:p")
  local out = vim.system({ "chezmoi", "source-path", file }, { text = true }):wait()
  local source_file = out.code == 0 and vim.trim(out.stdout or "") or ""

  if source_file ~= "" then
    vim.cmd("edit " .. vim.fn.fnameescape(source_file))
  else
    vim.notify("File is not managed by chezmoi", vim.log.levels.WARN)
  end
end, { desc = "Edit chezmoi source file" })

vim.api.nvim_create_user_command("ChezmoiApply", function()
  local file = vim.fn.expand("%:p")
  vim.fn.system("chezmoi apply " .. vim.fn.shellescape(file))
  vim.notify("✓ Applied " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
  vim.cmd("edit!") -- Reload file
end, { desc = "Apply chezmoi changes to target" })

vim.api.nvim_create_user_command("ChezmoiReAdd", function()
  local file = vim.fn.expand("%:p")
  vim.fn.system("chezmoi re-add " .. vim.fn.shellescape(file))
  vim.notify("✓ Re-added " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
end, { desc = "Re-add file to chezmoi" })

vim.api.nvim_create_user_command("ChezmoiDiff", function()
  local file = vim.fn.expand("%:p")
  local diff = vim.fn.system("chezmoi diff " .. vim.fn.shellescape(file))

  if diff == "" then
    vim.notify("No differences", vim.log.levels.INFO)
    return
  end

  -- Open diff in a new buffer
  vim.cmd("new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(diff, "\n"))
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
end, { desc = "Show chezmoi diff for current file" })

-- Optional: Add keybindings (uncomment if desired)
-- vim.keymap.set("n", "<leader>ce", ":ChezmoiEdit<CR>", { desc = "Chezmoi: Edit source" })
-- vim.keymap.set("n", "<leader>ca", ":ChezmoiApply<CR>", { desc = "Chezmoi: Apply" })
-- vim.keymap.set("n", "<leader>cr", ":ChezmoiReAdd<CR>", { desc = "Chezmoi: Re-add" })
-- vim.keymap.set("n", "<leader>cd", ":ChezmoiDiff<CR>", { desc = "Chezmoi: Diff" })

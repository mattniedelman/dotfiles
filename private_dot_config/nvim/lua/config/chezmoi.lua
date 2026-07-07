-- Chezmoi integration for Neovim
-- Automatically prompts to edit source file when opening a chezmoi-managed file

-- Cache for managed files to avoid repeated chezmoi calls
local managed_files_cache = {}
local cache_timestamp = 0
local CACHE_TTL = 300 -- 5 minutes in seconds

-- Get list of chezmoi-managed files
local function get_managed_files()
  local current_time = os.time()

  -- Return cached result if still valid
  if current_time - cache_timestamp < CACHE_TTL and next(managed_files_cache) ~= nil then
    return managed_files_cache
  end

  -- Refresh cache
  managed_files_cache = {}
  local handle = io.popen("chezmoi managed --include=all 2>/dev/null")
  if handle then
    for line in handle:lines() do
      managed_files_cache[line] = true
    end
    handle:close()
    cache_timestamp = current_time
  end

  return managed_files_cache
end

-- Check if a file is managed by chezmoi
local function is_managed(filepath)
  local managed = get_managed_files()
  return managed[filepath] == true
end

-- Get the source path for a managed file
local function get_source_path(filepath)
  local handle = io.popen("chezmoi source-path " .. vim.fn.shellescape(filepath) .. " 2>/dev/null")
  if not handle then
    return nil
  end

  local source_path = handle:read("*l")
  handle:close()

  return source_path
end

-- Main autocmd to handle opening chezmoi-managed files
vim.api.nvim_create_autocmd("BufRead", {
  group = vim.api.nvim_create_augroup("ChezmoiAutoEdit", { clear = true }),
  callback = function(args)
    local file = vim.fn.expand("%:p")

    -- Skip if file is empty or doesn't exist
    if file == "" or vim.fn.filereadable(file) == 0 then
      return
    end

    -- Get chezmoi source path
    local source_path_cmd = vim.fn.system("chezmoi source-path 2>/dev/null")
    local source_path = vim.trim(source_path_cmd)

    -- Skip if already in chezmoi source directory
    if source_path ~= "" and file:find(source_path, 1, true) == 1 then
      return
    end

    -- Check if file is managed by chezmoi
    if not is_managed(file) then
      return
    end

    -- Get the source file path
    local source_file = get_source_path(file)
    if not source_file or source_file == "" then
      return
    end

    -- Prompt user to edit source instead
    vim.schedule(function()
      local choice = vim.fn.confirm(
        "This file is managed by chezmoi.\nEdit source instead?",
        "&Yes\n&No\n&Always edit target",
        1
      )

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
  end,
})

-- Custom commands for chezmoi operations
vim.api.nvim_create_user_command("ChezmoiEdit", function()
  local file = vim.fn.expand("%:p")
  local source_file = get_source_path(file)

  if source_file and source_file ~= "" then
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

-- local function load_prompts(prompt_dir)
--   local prompts = {}
--   local files = vim.fn.glob(prompt_dir .. "/*.md", false, true)
--
--   for _, file in ipairs(files) do
--     local name = vim.fn.fnamemodify(file, ":t:r")
--     local content = table.concat(vim.fn.readfile(file), "\n")
--     prompts[name] = { prompt = content, system_prompt = content }
--   end
--
--   return prompts
-- end
-- local function CopilotInsertInline(prompt, context, bufnr)
--   local chat = require("CopilotChat")
--   chat.reset()
--   chat.ask(prompt, {
--     context = context,
--     headless = true,
--     system_prompt = "/COPILOT_INSTRUCTIONS",
--     callback = function(response)
--       -- Convert response to table of lines and ensure it's always an array
--       local lines = type(response) == "string" and vim.split(response, "\n")
--         or (type(response) == "table" and response or {})
--       table.insert(lines, "")
--
--       -- Insert the response at cursor position
--       vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
--
--       -- Set cursor on the last line
--       vim.cmd("normal! G")
--       return response
--     end,
--   })
-- end
--
-- vim.api.nvim_create_user_command("CopilotCommitMessage", function()
--   local prompt = "/commit"
--   local bufnr = vim.api.nvim_get_current_buf()
--
--   local context = "git:staged"
--
--   CopilotInsertInline(prompt, context, bufnr)
-- end, {})

return {
  {
    "zbirenbaum/copilot.lua",
    opts = {},
  },
}

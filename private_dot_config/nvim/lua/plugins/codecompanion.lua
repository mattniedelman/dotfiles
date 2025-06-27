vim.cmd([[cab cc CodeCompanion]])

local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local group = vim.api.nvim_create_augroup("CodeCompanionFidgetHooks", { clear = true })
vim.api.nvim_create_autocmd({ "User" }, {
  pattern = "CodeCompanion*",
  group = group,
  callback = function(request)
    if request.match == "CodeCompanionChatSubmitted" then
      return
    end

    local msg

    msg = "[CodeCompanion] " .. request.match:gsub("CodeCompanion", "")

    vim.notify(msg, "info", {
      timeout = 1000,
      id = "code_companion_status",
      title = "Code Companion Status",
      opts = function(notif)
        notif.icon = ""
        if vim.endswith(request.match, "Started") then
          ---@diagnostic disable-next-line: undefined-field
          notif.icon = spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
        elseif vim.endswith(request.match, "Finished") then
          notif.icon = " "
        end
      end,
    })
  end,
})
return {
  {
    "olimorris/codecompanion.nvim",
    lazy = false,
    keys = {
      { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", noremap = true, desc = "CodeCompanion Chat", silent = true },
      {
        "<leader>ag",
        function()
          require("codecompanion").prompt("commit_msg")
        end,
        desc = "Commit Message",
        noremap = true,
        silent = true,
      },
      {
        "<leader>ad",
        function()
          require("codecompanion").prompt("docstring")
        end,
        desc = "Docstring",
        noremap = true,
        silent = true,
      },
    },
    opts = {
      display = {
        diff = {
          provider = "mini_diff",
        },
      },
      prompt_library = {
        ["fix_lsp"] = {
          strategy = "workflow",
          description = "Fix LSP issues",
          opts = {
            short_name = "fix_lsp",
            stop_context_insertion = false,
            user_prompt = false,
          },
          prompts = {
            {
              {
                role = "system",
                opts = {
                  visible = true,
                },
                content = function()
                  vim.g.codecompanion_auto_tool_mode = true
                  local prompt_str = [[
### Instructions

You are a coding assistant whose task is to address diagnostic issues in the current buffer, such as warning, errors, or suggestions provided by the LSP.

### Steps to Follow

You are required to write code following the instructions provided above and and evaluating correctness using the diagnostics provided by #lsp. Follow these steps exactly:

1. Select a single diagnostic message to address from #lsp.
2. Update the code as necessary using the tools available to you to address the message while maintaining the original intent of the code.
3. Make sure you perform both steps in the same response

We'll repeat this cycle until all diagnostic messages are resolved. Ensure no deviations from these steps.]]
                  return prompt_str
                end,
              },
              {
                role = "user",
                opts = {
                  auto_submit = true,
                  contains_code = true,
                },
                content = "#lsp #buffer use @files to fix a diagnostic message",
              },
            },
            {
              {
                role = "user",
                opts = { auto_submit = true },
                repeat_until = function(chat)
                  return chat.tools.flags.has_diagnostics == false
                end,
                content = "#lsp There are still diagnostic messages remaining.  Please fix another one",
              },
            },
          },
        },
        ["docstring"] = {
          strategy = "inline",
          description = "Generate a docstring for the function under cursor",
          opts = {
            auto_submit = true,
            short_name = "docstring",
            placement = "add",
            modes = { "v" },
            user_prompt = false,
            stop_context_insertion = true,
          },
          prompts = {
            {
              role = "system",
              opts = {
                visible = false,
              },
              content = [[
You are a coding assistant whose task is to generate docstrings for existing Python code.
You will receive code without any docstrings.
Generate the appropiate docstrings for each function, class or method.

Do not return any code. Use the context only to learn about the code.
Write documentation only for the code provided as input code.

The docstring for a function or method should summarize its behavior, side effects, exceptions raised,
and restrictions on when it can be called (all if applicable).
Only mention exceptions if there is at least one _explicitly_ raised or reraised exception inside the function or method.
The docstring prescribes the function or method's effect as a command, not as a description; e.g. don't write "Returns the pathname ...".
Do not explain implementation details, do not include information about arguments and return here.
If the docstring is multiline, the first line should be a very short summary, followed by a blank line and a more ellaborate description.
Write single-line docstrings if the function is simple.
The docstring for a class should summarize its behavior and list the public methods (one by line) and instance variables.
]],
            },
            {
              role = "user",
              opts = {
                contains_code = true,
              },
              content = function(context)
                local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
                local prompt_str = [[<user_prompt>
Please generate docstrings for this code from buffer %d:
```%s
%s
```
</user_prompt>
]]

                return string.format(prompt_str, context.bufnr, context.filetype, code)
              end,
            },
          },
        },
        ["commit"] = {
          strategy = "inline",
          description = "Generate a commit message based on staged changes",
          opts = {
            auto_submit = true,
            short_name = "commit_msg",
            placement = "replace",
          },
          prompts = {
            {
              role = "user",
              content = function()
                local prompt_str =
                  [[I want you to act as a conventional commit message generator following the Conventional Commits specification. Given the git diff below, you will generate a properly formatted commit message. The structure must be: [optional scope]: , followed by optional body and footers. Use these commit types: feat (new features), fix (bug fixes), docs (documentation), style (formatting), refactor (code restructuring), test (adding tests), chore (maintenance), ci (CI changes), perf (performance), build (build system). Include scope in parentheses when relevant (e.g., feat(api):). For breaking changes, add ! after type/scope or include BREAKING CHANGE: footer. The description should be imperative mood, lowercase, no period. Body should explain what and why, not how. (This is just an example, make sure to not use anything from in this example in actual commit message) The output should only contains commit message and nothing more. Do not include markdown code blocks in output
  ```diff
    %s
  ```
  ]]
                local diff = vim.fn.system("git diff --staged")
                return string.format(prompt_str, diff)
              end,
              opts = {
                contains_code = true,
              },
            },
          },
        },
      },
      -- adapters = {
      --   copilot = function()
      --     return require("codecompanion.adapters").extend("copilot", {
      --       schema = {
      --         model = {
      --           default = "claude-opus-4",
      --         },
      --       },
      --     })
      --   end,
      -- },

      opts = {
        log_level = "DEBUG",
      },
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            make_vars = true,
            make_slash_commands = true,
            show_result_in_chat = true,
          },
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/mcphub.nvim",
    },
  },
  {
    "ravitemer/mcphub.nvim",
    build = "npm install -g mcp-hub@latest",
    opts = {
      auto_approve = function(params)
        if vim.g.codecompanion_auto_tool_mode then
          return true
        end

        -- Auto-approve safe file operations in current project
        if params.tool_name == "read_file" then
          local path = params.arguments.path or ""
          if path:match("^" .. vim.fn.getcwd()) then
            return true -- Auto approve
          end
        end

        if params.is_auto_approved_in_server then
          return true -- Respect servers.json configuration
        end

        if
          params.tool_name == "fetch"
          and params.arguments.url == "https://www.conventionalcommits.org/en/v1.0.0/#specification"
        then
          return true
        end

        return false -- Default behavior is to not auto-approve
      end,
    },
    config = function()
      require("mcphub").setup()

      local lualine = require("lualine")
      local config = lualine.get_config()
      table.insert(config.sections.lualine_x, require("mcphub.extensions.lualine"))
      require("lualine").setup(config)
    end,
  },
}

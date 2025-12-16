-- AI Assistance
-- AI-powered coding tools and assistants
--
-- This configuration includes:
-- 1. Augment.vim - For inline code completions (uses Ctrl+F to accept)
-- 2. Sidekick - For AI CLI tools integration and Next Edit Suggestions
--
-- Prerequisites:
--   1. Install Auggie CLI: https://docs.augmentcode.com/cli/installation
--   2. Authenticate: Run `auggie auth login` in your terminal
--   3. Verify: Run `auggie --version` to confirm installation
--   4. Install AI CLI tools (optional): claude, copilot, gemini, etc.
--
-- Key bindings:
--   <Tab> - Navigate/apply Next Edit Suggestions
--   <leader>aa - Toggle Sidekick CLI
--   <leader>as - Select AI CLI tool
--   <leader>ad - Detach CLI session
--   <leader>at - Send current context to CLI
--   <leader>af - Send file to CLI
--   <leader>av - Send visual selection to CLI
--   <leader>ap - Select prompt to send
--   <leader>ac - Toggle Claude CLI
--
-- Differences from augment.vim:
--   - augment.vim: Provides inline code completions (autocomplete-style)
--   - Sidekick: Provides AI CLI integration and Next Edit Suggestions
--   Both work together seamlessly.

return {
  {
    "augmentcode/augment.vim",
    branch = "main",
    lazy = false,
    init = function()
      -- vim.g.augment_workspace_folders = { "~/git/imprivata" }
      vim.g.augment_workspace_folders = { require("lazyvim.util").root() }
      vim.g.augment_disable_tab_mapping = true
    end,
  },
  {
    "folke/sidekick.nvim",
    opts = {
      cli = {
        mux = {
          backend = "tmux",
          enabled = false, -- Set to true if you want persistent sessions
        },
        win = {
          layout = "right", -- float|left|bottom|top|right
        },
        tools = {
          -- Add auggie to the list of available CLI tools
          auggie = {
            cmd = { "auggie" },
          },
        },
        prompts = {
          -- Custom prompts matching your previous workflow
          explain = "Explain {this}",
          fix = "Can you fix {this}?",
          tests = "Can you write tests for {this}?",
          commit = "Can you review my changes?",
          lsp = "Can you help me fix the diagnostics in {file}?\n{diagnostics}",
        },
      },
    },
    keys = {
      -- Tab for Next Edit Suggestions
      {
        "<tab>",
        function()
          -- if there is a next edit, jump to it, otherwise apply it if any
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>" -- fallback to normal tab
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      -- Quick access to specific tools (example with auggie)
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle({ name = "auggie", focus = true })
        end,
        desc = "Sidekick Toggle Auggie",
      },
      -- Select CLI tool
      {
        "<leader>as",
        function()
          require("sidekick.cli").select()
        end,
        desc = "Select CLI",
      },
      -- Detach session
      {
        "<leader>ad",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Detach CLI Session",
      },
      -- Send context
      {
        "<leader>at",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      -- Send file
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send File",
      },
      -- Send visual selection
      {
        "<leader>av",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      -- Prompt selector
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
      -- Prompt shortcuts (matching your previous workflow)
      {
        "<leader>ae",
        function()
          require("sidekick.cli").send({ msg = "{explain}" })
        end,
        mode = { "n", "v" },
        desc = "Explain Code",
      },
      {
        "<leader>al",
        function()
          require("sidekick.cli").send({ msg = "{lsp}" })
        end,
        mode = { "n", "v" },
        desc = "Explain LSP",
      },
      {
        "<leader>ag",
        function()
          require("sidekick.cli").send({ msg = "{commit}" })
        end,
        mode = { "n", "v" },
        desc = "Commit Message",
      },
    },
  },
}

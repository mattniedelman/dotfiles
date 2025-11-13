-- AI Assistance
-- AI-powered coding tools and assistants
--
-- This configuration includes:
-- 1. Augment.vim - For inline code completions (uses Ctrl+F to accept)
-- 2. CodeCompanion - For AI chat, inline transformations, and agentic workflows
--
-- CodeCompanion is configured to use Augment via ACP (Agent Client Protocol).
-- Augment's Auggie CLI provides powerful agentic capabilities with deep codebase
-- understanding through Augment's industry-leading context engine.
--
-- Prerequisites:
--   1. Install Auggie CLI: https://docs.augmentcode.com/cli/installation
--   2. Authenticate: Run `auggie auth login` in your terminal
--   3. Verify: Run `auggie --version` to confirm installation
--
-- Key bindings:
--   <leader>aa - Open CodeCompanion action palette
--   <leader>ac - Toggle CodeCompanion chat
--   <leader>ap - Open new CodeCompanion chat
--   <leader>ai - CodeCompanion inline assistant
--   <leader>at - Add selection to chat (visual mode)
--   <Ctrl-.>   - Toggle CodeCompanion chat
--
-- ACP Support:
--   Auggie CLI is a built-in ACP adapter in CodeCompanion. The adapter name is
--   "auggie_cli" (note the _cli suffix). No custom adapter configuration is needed
--   unless you want to extend the default behavior.
--
-- Differences from augment.vim:
--   - augment.vim: Provides inline code completions (autocomplete-style)
--   - CodeCompanion + Auggie: Provides chat, agentic workflows, and transformations
--   Both use Augment's context engine and work together seamlessly.

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
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
    opts = {
      adapters = {
        -- Auggie CLI adapter is built-in to CodeCompanion
        -- No custom configuration needed unless you want to extend it
        -- See: https://codecompanion.olimorris.dev/configuration/acp.html
      },
      strategies = {
        chat = {
          adapter = "auggie_cli",
        },
        inline = {
          adapter = "auggie_cli",
        },
        agent = {
          adapter = "auggie_cli",
        },
      },
      display = {
        chat = {
          window = {
            layout = "vertical", -- float|vertical|horizontal|buffer
            border = "rounded",
            height = 0.8,
            width = 0.45,
            relative = "editor",
            opts = {
              breakindent = true,
              cursorcolumn = false,
              cursorline = false,
              foldcolumn = "0",
              linebreak = true,
              list = false,
              signcolumn = "no",
              spell = false,
              wrap = true,
            },
          },
          intro_message = "Welcome to CodeCompanion! Type your message below or use `/` for slash commands.",
          show_settings = true,
          show_token_count = true,
        },
        inline = {
          diff = {
            enabled = true,
            priority = 130,
          },
        },
      },
    },
    keys = {
      {
        "<leader>aa",
        "<cmd>CodeCompanionActions<cr>",
        mode = { "n", "v" },
        desc = "CodeCompanion Actions",
      },
      {
        "<leader>ac",
        "<cmd>CodeCompanionChat Toggle<cr>",
        mode = { "n", "v" },
        desc = "CodeCompanion Chat Toggle",
      },
      {
        "<leader>ap",
        "<cmd>CodeCompanionChat<cr>",
        mode = { "n", "v" },
        desc = "CodeCompanion Chat",
      },
      {
        "<c-.>",
        "<cmd>CodeCompanionChat Toggle<cr>",
        mode = { "n", "v" },
        desc = "CodeCompanion Chat Toggle",
      },
      {
        "<leader>ai",
        "<cmd>CodeCompanion<cr>",
        mode = { "n", "v" },
        desc = "CodeCompanion Inline",
      },
      {
        "<leader>at",
        "<cmd>CodeCompanionChat Add<cr>",
        mode = "v",
        desc = "CodeCompanion Add to Chat",
      },
    },
  },
}


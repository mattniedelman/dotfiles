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
          -- Disable ctrl+p in sidekick windows to avoid conflict with auggie's enhance prompt
          keys = {
            prompt = false, -- Disable ctrl+p for prompt selector
          },
        },
        tools = {
          auggie = {
            cmd = { "auggie" },
          },
        },
        prompts = {
          explain = "Explain {this}",
          fix = "Can you fix {this}?",
          tests = "Can you write tests for {this}?",
          commit = "Generate a concise git commit message for my staged changes. Use conventional commit format (type: description). Be specific about what changed. Only output the commit message, nothing else.",
          lsp = "Can you help me fix the diagnostics in {file}?\n{diagnostics}",
        },
      },
    },
    keys = {
      {
        "<tab>",
        function()
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>"
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
        desc = "Generate Commit Message",
      },
    },
  },
}

-- AI Assistance
-- AI-powered coding tools and assistants

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
    lazy = false,
    opts = {
      cli = {
        -- Configure auggie as a custom AI CLI tool
        tools = {
          auggie = {
            cmd = { "auggie" },
          },
        },
      },
      -- Disable default keybindings to avoid conflicts with auggie's prompt enhancer
      keys = false,
    },
    keys = {
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
      {
        "<c-.>",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Sidekick Toggle",
        mode = { "n", "t", "i", "x" },
      },
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Sidekick Toggle CLI",
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select()
        end,
        desc = "Select CLI",
      },
      {
        "<leader>ad",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Detach a CLI Session",
      },
      {
        "<leader>at",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
      -- Note: Ctrl+P is intentionally not mapped to avoid conflict with auggie's prompt enhancer
      -- Use <leader>ap instead for Sidekick prompt selection
      -- Keybinding to open Auggie directly
      {
        "<leader>ag",
        function()
          require("sidekick.cli").toggle({ name = "auggie", focus = true })
        end,
        desc = "Sidekick Toggle Auggie",
      },
    },
    -- Configure terminal window keybindings to avoid Ctrl+P conflict
    -- while preserving other useful terminal functionality
    opts = function(_, opts)
      opts.cli = opts.cli or {}
      opts.cli.win = opts.cli.win or {}
      opts.cli.win.keys = opts.cli.win.keys or {}

      -- Override the default Ctrl+P keybinding to disable it
      opts.cli.win.keys.prompt = false

      -- Keep other useful terminal keybindings
      opts.cli.win.keys.buffers = { "<c-b>", "buffers", mode = "nt", desc = "open buffer picker" }
      opts.cli.win.keys.files = { "<c-f>", "files", mode = "nt", desc = "open file picker" }
      opts.cli.win.keys.hide_n = { "q", "hide", mode = "n", desc = "hide the terminal window" }
      opts.cli.win.keys.hide_ctrl_q = { "<c-q>", "hide", mode = "n", desc = "hide the terminal window" }
      opts.cli.win.keys.hide_ctrl_dot = { "<c-.>", "hide", mode = "nt", desc = "hide the terminal window" }
      opts.cli.win.keys.hide_ctrl_z = { "<c-z>", "hide", mode = "nt", desc = "hide the terminal window" }
      opts.cli.win.keys.stopinsert = { "<c-q>", "stopinsert", mode = "t", desc = "enter normal mode" }

      return opts
    end,
  },
}


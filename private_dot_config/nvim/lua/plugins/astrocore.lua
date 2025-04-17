return {
  "AstroNvim/astrocore",
  opts = {
    rooter = {
      autochdir = true,
    },
    features = {
      large_buf = { size = 1024 * 500, lines = 10000 },
      autopairs = false,
      cmp = false,
      diagnostics_mode = 3,
      highlighturl = true,
      notifications = true,
    },

    diagnostics = {
      virtual_text = false,
      underline = true,
      update_in_insert = false,
    },

    options = {
      opt = {
        tabstop = 4,
        relativenumber = true,
        number = true,
        spell = false,
        signcolumn = "auto",
        wrap = false,
      },
      g = {
        ai_accept = function()
          if require("copilot.suggestion").is_visible() then
            require("copilot.suggestion").accept()
            return true
          end
        end,
      },
    },
    mappings = {
      i = {
        ["<C-a>"] = { "<ESC>^", desc = "beginning of line" },
        ["<C-e>"] = { "<ESC>$", desc = "end of line" },
      },
      v = {
        ["<Leader>q"] = {
          "<Cmd>confirm q<CR>",
          desc = "Quit Window",
        },
        ["<Leader>Q"] = {
          "<Cmd>confirm qall<CR>",
          desc = "Exit AstroNvim",
        },
      },
      n = {
        q = false,
        Q = false,

        L = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        H = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        ["<C-a>"] = { "^", desc = "beginning of line" },
        ["<C-e>"] = { "$", desc = "end of line" },

        ["<Leader>bD"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Pick to close",
        },

        ["<Leader>b"] = { desc = "Buffers" },
        ["<Leader>c"] = false,
      },
      t = {},
    },
  },
}

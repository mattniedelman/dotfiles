return {
  {
    "zbirenbaum/copilot.lua",
    opts = function(_, opts)
      opts.suggestion = {
        enabled = false,
        auto_trigger = true,
      }
    end,
  },
  {

    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require "cmp"

      table.insert(opts.sources, 1, {
        name = "copilot",
        group_index = 1,
        priority = 10000,
      })

      opts.preselect = cmp.PreselectMode.None
      opts.completion = {
        completeopt = "noselect",
      }
      cmp.setup {
        mapping = {
          ["<Tab>"] = function(fallback) fallback() end,
        },
      }

      require("astrocore").extend_tbl(opts, {
        mapping = {
          ["<C-f>"] = cmp.mapping.confirm { select = true },
        },
      })
    end,
  },
}

-- UI & Appearance
-- Visual customization and interface configuration

return {
  -- Colorscheme
  {
    "thesimonho/kanagawa-paper.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-paper",
    },
  },

  -- Picker UI
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        -- Configure window options for the picker
        win = {
          -- Configure the preview window to enable text wrapping
          preview = {
            wo = {
              wrap = true, -- Enable line wrapping
              linebreak = true, -- Wrap at word boundaries for better readability
            },
          },
        },
      },
    },
  },

  -- Log file highlighting
  {
    "fei6409/log-highlight.nvim",
    opts = {},
  },
}


-- Editing Enhancements
-- Improvements to the editing experience

return {
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter", -- Only needed in insert mode
    config = function()
      require("better_escape").setup({
        mappings = {
          i = {
            f = {
              d = "<Esc>",
            },
          },
        },
      })
    end,
  },
  {
    "nvim-mini/mini.pairs",
    enabled = false,
  },
}


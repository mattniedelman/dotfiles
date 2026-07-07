-- Navigation & Discovery
-- Tools for moving around and discovering features

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 0,
      spec = {
        { "<leader>a", group = "AI" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
  {
    "swaits/zellij-nav.nvim",
    event = "VeryLazy",
    keys = {
      { "<C-h>", "<cmd>ZellijNavigateLeft<cr>", desc = "Navigate left" },
      { "<C-j>", "<cmd>ZellijNavigateDown<cr>", desc = "Navigate down" },
      { "<C-k>", "<cmd>ZellijNavigateUp<cr>", desc = "Navigate up" },
      { "<C-l>", "<cmd>ZellijNavigateRight<cr>", desc = "Navigate right" },
    },
  },
}

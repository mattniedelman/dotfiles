-- Navigation & Discovery
-- Tools for moving around and discovering features

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 0,
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
    "knubie/vim-kitty-navigator",
    build = "cp ./*.py ~/.config/kitty/",
    keys = {
      { "<C-h>", "<cmd>KittyNavigateLeft<cr>", { noremap = true, silent = true } },
      { "<C-j>", "<cmd>KittyNavigateDown<cr>", { noremap = true, silent = true } },
      { "<C-k>", "<cmd>KittyNavigateUp<cr>", { noremap = true, silent = true } },
      { "<C-l>", "<cmd>KittyNavigateRight<cr>", { noremap = true, silent = true } },
    },
  },
}


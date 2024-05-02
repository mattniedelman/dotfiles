return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      indent = {
        enable = false,
      },

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { "python" },
      },
    },
  },
}

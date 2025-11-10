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
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    opts = {
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["ab"] = "@block.outer",
            ["ib"] = "@block.inner",
            ["al"] = "@loop.outer",
            ["il"] = "@loop.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
          },
        },
      },
    },
  },
  { "nvim-treesitter/nvim-treesitter-context", opts = {} },
}

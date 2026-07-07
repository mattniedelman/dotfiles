-- Syntax Parsing & Understanding
-- Treesitter and code parsing configuration

-- Register Quint filetype
vim.filetype.add({
  extension = {
    qnt = "quint",
  },
})

-- Register Quint parser for nvim-treesitter (new API)
vim.api.nvim_create_autocmd("User", {
  pattern = "TSUpdate",
  callback = function()
    require("nvim-treesitter.parsers").quint = {
      install_info = {
        url = "https://github.com/gruhn/tree-sitter-quint",
        branch = "release",
      },
    }
  end,
})

-- Register the parser with Neovim's treesitter
vim.treesitter.language.register("quint", { "quint" })

-- Enable treesitter highlighting for quint files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "quint",
  callback = function()
    vim.treesitter.start()
  end,
})

return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" }, -- Load when opening/creating files
    opts = {
      indent = {
        enable = false,
      },

      highlight = {
        enable = true,
        disable = { "dockerfile" }, -- Disable treesitter for Dockerfiles
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

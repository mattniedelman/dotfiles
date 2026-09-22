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
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    -- main branch: select keymaps are created manually (the old
    -- opts.textobjects.select.keymaps table is not read on this branch).
    opts = {
      select = {
        lookahead = true,
      },
    },
    keys = function()
      local maps = {
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
      }
      local keys = {}
      for lhs, capture in pairs(maps) do
        keys[#keys + 1] = {
          lhs,
          function()
            require("nvim-treesitter-textobjects.select").select_textobject(capture, "textobjects")
          end,
          mode = { "x", "o" },
          desc = "Select " .. capture,
        }
      end
      return keys
    end,
  },
  { "nvim-treesitter/nvim-treesitter-context", opts = {} },
}

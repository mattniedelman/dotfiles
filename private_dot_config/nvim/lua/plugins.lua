local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  })
  vim.o.runtimepath = vim.fn.stdpath("data") .. "/site/pack/*/start/*," .. vim.o.runtimepath
end

require("packer").startup(function(use)
  use("wbthomason/packer.nvim")
  use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
  use("sheerun/vim-polyglot")
  use("nvim-lua/plenary.nvim")
  use({
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
  })
  use({ "lukas-reineke/lsp-format.nvim" })
  use({ "jose-elias-alvarez/null-ls.nvim", "jay-babu/mason-null-ls.nvim" })

  use({
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup({
        position = "right",
        auto_open = false,
      })
    end,
  })
  use("petobens/poet-v")
  use("ntpeters/vim-better-whitespace")
  use({ "tpope/vim-commentary" })

  use({
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-nvim-lua",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-vsnip",
    "hrsh7th/vim-vsnip",
    "ray-x/cmp-treesitter",
  })

  use({ "arcticicestudio/nord-vim" })
  if packer_bootstrap then
    require("packer").sync()
  end
end)

vim.cmd.colorscheme({ "nord" })


require("mason").setup({ pip = { upgrade_pip = true } })
require("mason-lspconfig").setup({
  ensure_installed = {
    "ansiblels",
    "awk_ls",
    "bashls",
    "dagger",
    "dockerls",
    "gopls",
    "jsonls",
    "ruff_lsp",
    "jedi_language_server",
    "sumneko_lua",
    "pylsp",
    "taplo",
    "yamlls",
  },
})

local null_ls = require("null-ls")
null_ls.setup({
  log_level = "trace",
  sources = {
    -- null_ls.builtins.code_actions.refactoring,
    -- null_ls.builtins.diagnostics.todo_comments,
    null_ls.builtins.diagnostics.actionlint,
    null_ls.builtins.diagnostics.checkmake,
    null_ls.builtins.diagnostics.fish,
    null_ls.builtins.diagnostics.hadolint,
    null_ls.builtins.diagnostics.shellcheck,
    null_ls.builtins.diagnostics.staticcheck,
    null_ls.builtins.diagnostics.tfsec,
    null_ls.builtins.formatting.fish_indent,
    null_ls.builtins.formatting.gofmt,
    null_ls.builtins.formatting.jq,
    null_ls.builtins.formatting.prettierd,
    null_ls.builtins.formatting.shellharden,
    null_ls.builtins.formatting.shfmt,
    null_ls.builtins.formatting.taplo,
    null_ls.builtins.formatting.xmllint,
    null_ls.builtins.formatting.yamlfmt,
  },
})
require("mason-null-ls").setup({
  ensure_installed = nil,
  automatic_installation = true,
  automatic_setup = true,
})

vim.g.python3_host_prog = "/home/mattniedelman/.cache/pypoetry/virtualenvs/neovim-0WD0XgmR-py3.10/bin/python"
vim.g.poetv_executables = { "poetry" }
vim.g.poetv_auto_activate = 1

vim.g.better_whitespace_enabled = 1
vim.g.show_spaces_that_precede_tabs = 1
vim.g.strip_whitelines_at_eof = 1
vim.g.strip_whitespace_confirm = 0
vim.g.strip_whitespace_on_save = 1

local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp",
      entry_filter = function(entry, ctx)
        return require('cmp.types').lsp.CompletionItemKind[entry:get_kind()] ~= 'Text'
      end },
    { name = "vsnip" },
    { name = "treesitter" },
    { name = "path" },
    { name = "nvim_lua" },
  }),
})

cmp.setup.filetype("gitcommit", {
  sources = cmp.config.sources({
    { name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
  }, {
    { name = "buffer" },
  }),
})

cmp.setup.cmdline({ "/", "?" }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" },
  },
})

cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path" },
  }, {
    { name = "cmdline" },
  }),
})


require("lsp-format").setup({})
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)

local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
  vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format({ async = true })
  end, bufopts)

  if vim.bo.filetype == "python" then
    vim.cmd.PylspInstall({
      mods = { silent = true },
      args = {
        "pyls-flake8",
        "pylsp-mypy",
        "python-lsp-black",
        "pyls-memestra",
        "pylsp-rope",
        "pyls-isort",
      },
    })
  end
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("mason-null-ls").setup_handlers({})
require("mason-lspconfig").setup_handlers({
  function(lsp)
    require("lspconfig")[lsp].setup({ on_attach = on_attach, capabilities = capabilities })
  end,
  ["sumneko_lua"] = function()
    require("lspconfig").sumneko_lua.setup({
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" }
          }
        }
      }
    })
  end
})


vim.g.slime_target = 'kitty'
vim.g.slime_python_ipython = 1

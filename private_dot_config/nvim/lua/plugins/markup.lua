-- Data & Markup Languages
-- Configuration and documentation formats: YAML, JSON, Markdown, TOML
--
-- Note: yamlls and jsonls are configured by LazyVim extras (lang.yaml, lang.json)
-- with SchemaStore support for automatic schema detection and validation

return {
  -- LSP servers for markup/data languages
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "yamlls", -- YAML (configured by LazyVim lang.yaml extra)
        "jsonls", -- JSON (configured by LazyVim lang.json extra)
        "jqls", -- JSON/jq
        "marksman", -- Markdown (configured by LazyVim lang.markdown extra)
        "tombi", -- TOML
      },
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
      "b0o/SchemaStore.nvim", -- JSON/YAML schemas (used by LazyVim extras)
    },
  },

  -- Install formatters for markup/data languages
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "jq", -- JSON processor/formatter
        "yamlfmt", -- YAML formatter (supports yamllint-compatible options)
        "doctoc", -- Markdown TOC generator
      },
    },
  },

  -- Configure formatters for markup/data languages
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.json = { "jq" }
      opts.formatters_by_ft.yaml = { "yamlfmt" }
    end,
  },

  -- Markdown table of contents (doctoc)
  -- Auto-generates/updates TOC on save for all markdown files
  -- Add <!-- DOCTOC SKIP --> to skip a file
  {
    "nvim-lua/plenary.nvim", -- dependency for async job
    ft = "markdown",
    config = function()
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = "*.md",
        callback = function()
          local file = vim.fn.expand("%:p")
          vim.fn.jobstart({ "doctoc", "--notitle", file }, {
            on_exit = function(_, code)
              if code == 0 then
                vim.schedule(function()
                  vim.cmd("checktime")
                end)
              end
            end,
          })
        end,
      })
    end,
  },
}


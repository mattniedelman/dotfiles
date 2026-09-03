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
        "marksman", -- Markdown LSP
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
        "rumdl", -- Markdown formatter/linter; mirrors hk rumdl_format + rumdl steps
      },
    },
  },

  -- rumdl LSP: inline lint diagnostics matching hk rumdl step.
  -- Not in nvim-lspconfig's built-in registry; defined via vim.lsp.config.
  -- Requires rumdl on PATH (mise use -g rumdl or cargo install rumdl).
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rumdl = {
          cmd = { "rumdl", "lsp" },
          filetypes = { "markdown" },
          root_markers = { ".git", "rumdl.toml", ".rumdl.toml" },
        },
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
      opts.formatters_by_ft.markdown = { "rumdl_format", "mdreflow" }
      opts.formatters = opts.formatters or {}
      -- rumdl fmt formats in place; mirrors hk rumdl_format builtin
      opts.formatters.rumdl_format = {
        command = "rumdl",
        args = { "fmt", "$FILENAME" },
        stdin = false,
      }
      -- mdreflow prose reflow (sentence-per-line); mirrors hk mdreflow step.
      -- Formats in place; --config points at the global default.
      opts.formatters.mdreflow = {
        command = "mdreflow",
        args = { "--config", vim.fn.expand("~/.config/mdreflow/mdreflow.yaml"), "$FILENAME" },
        stdin = false,
      }
      -- Override conform's default `jq .` to use `jq -S` (sorted keys),
      -- matching hk json.pkl which aligns both check and fix to jq -S.
      opts.formatters.jq = {
        command = "jq",
        args = { "-S", "." },
        stdin = true,
      }
    end,
  },

  -- Disable render-markdown.nvim (replaced by markview.nvim)
  { "MeanderingProgrammer/render-markdown.nvim", enabled = false },

  -- Markdown previewer with wrap support for tables
  {
    "OXY2DEV/markview.nvim",
    ft = { "markdown", "norg", "rmd", "org", "vimwiki" },
    opts = {
      -- Uses defaults which include wrap support for tables
    },
  },
}

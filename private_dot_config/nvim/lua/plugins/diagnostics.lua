-- Diagnostics & Code Analysis
-- Linting, diagnostics, and code actions (general-purpose)
--
-- Note: LazyVim's lsp.none-ls extra adds formatters (stylua, shfmt, fish_indent, fish)
-- We use conform.nvim for formatting instead, so we only use none-ls for diagnostics/code actions

return {
  -- Install diagnostic tools
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "commitlint", -- Commit message linter
      },
    },
  },

  -- Configure none-ls diagnostics and code actions
  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile" }, -- Load when opening/creating files
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.root_dir = opts.root_dir
        or require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git")

      -- Filter out formatters from LazyVim's none-ls extra
      -- We use conform.nvim for formatting (stylua, shfmt, etc.)
      if opts.sources then
        opts.sources = vim.tbl_filter(function(source)
          -- Keep only non-formatting sources
          return source.method ~= nls.methods.FORMATTING
        end, opts.sources)
      end

      -- Add our custom diagnostics and code actions
      opts.sources = vim.list_extend(opts.sources or {}, {
        -- Git integration
        nls.builtins.code_actions.gitsigns,
        nls.builtins.code_actions.refactoring,
        nls.builtins.diagnostics.commitlint,
      })
    end,
  },
}

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      -- Customize or remove this keymap to your liking
      "<leader>f",
      function() require("conform").format { async = true, lsp_fallback = true } end,
      mode = "",
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      snakemake = { "snakemake" },
      lua = { "stylua" },
      fish = { "fish_indent" },
      sh = { "shfmt", "shellcheck" },
      python = { "isort", "black", "auto-optional" },
      json = { "jq" },
      go = { "gofumpt", "goimports" },
      markdown = { "mdslw", "markdownlint" },
      sql = { "sqlfmt" },
      dbt = { "sqlfmt" },
      d2 = { "d2fmt" },
      yaml = { "yq" },
      ["*"] = { "trim_whitespace", "trim_newlines", "typos" },
    },
    format_on_save = { timeout_ms = 1000, lsp_fallback = false },
    -- Customize formatters
    formatters = {
      shfmt = {
        prepend_args = { "-i", "2" },
      },
      sqlfmt = {
        command = "sqlfmt",
        args = { "-" },
      },
      d2fmt = {
        command = "d2",
        args = { "fmt", "-" },
      },
      snakemake = {
        command = "snakefmt",
        args = { "-" },
      },
    },
  },
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}

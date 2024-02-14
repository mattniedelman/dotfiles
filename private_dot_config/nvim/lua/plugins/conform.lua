return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        sqlfmt = {
          command = "sqlfmt",
          args = { "-" },
        },
      },

      formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt" },
        python = { "isort", "black", "ruff_format" },
        json = { "jq" },
        go = { "gofumpt", "goimports" },
        markdown = { "markdownlint", "mdslw" },
        yaml = { "yamlfix", "yamlfmt" },
        sql = { "sqlfmt" },
        dbt = { "sqlfmt" },
        ["*"] = { "trim_whitespace", "trim_newlines", "typos" },
      },
    },
  },
}

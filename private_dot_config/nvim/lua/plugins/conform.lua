return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "gofumpt",
        "goimports",
        "markdown-toc",
        "markdownlint-cli2",
        "sqlfmt",
      },
    },
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt", "shellcheck" },
        python = { "ruff_format", "ruff_organize_imports" },
        json = { "jq" },
        go = { "gofumpt", "goimports" },
        markdown = { "mdslw" },
        sql = { "sqlfmt" },
        dbt = { "sqlfmt" },
        d2 = { "d2fmt" },
        yaml = { "yq" },
        ["*"] = { "trim_whitespace", "trim_newlines", "typos" },
      },
      formatters = {
        ruff_fix = {
          command = "ruff",
          args = {
            "check",
            "--fix",
            "--force-exclude",
            "--exit-zero",
            "--no-cache",
            "--unfixable=F401",
            "--stdin-filename",
            "$FILENAME",
            "-",
          },
          stdin = true,
          cwd = require("conform.util").root_file({
            "pyproject.toml",
            "ruff.toml",
            ".ruff.toml",
          }),
        },
      },
    },
  },
}

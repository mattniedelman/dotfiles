return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt" },
        python = { "isort", "black" },
        json = { "jq" },
        go = { "gofumpt", "goimports" },
        markdown = { "markdown-toc", "markdownlint", "mdformat" },
        yaml = { "yamlfix" },
      },
    },
  },
}

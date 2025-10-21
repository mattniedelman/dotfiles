return {
  "mason-org/mason-lspconfig.nvim",
  opts = {
    ensure_installed = {
      "awk_ls",
      "bashls",
      "docker_language_server",
      "diagnosticls",
      "fish_lsp",
      "gh_actions_ls",
      "helm_ls",
      "jinja_lsp",
      "jqls",
      "lua_ls",
      "marksman",
      "spectral",
      "systemd_ls",
      "tombi",
      "vacuum",
      "yamlls",
    },
  },
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    "neovim/nvim-lspconfig",
  },
}

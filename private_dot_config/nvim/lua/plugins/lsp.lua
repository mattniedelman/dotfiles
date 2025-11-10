-- LSP Infrastructure & General Language Servers
-- Core LSP setup and language servers for general-purpose languages
-- Language-specific LSP servers are configured in their respective files:
--   - python.lua: ruff, zuban
--   - shell.lua: bashls, fish_lsp, awk_ls
--   - markup.lua: yamlls, jqls, marksman, tombi

return {
  "mason-org/mason-lspconfig.nvim",
  opts = {
    ensure_installed = {
      -- DevOps & Infrastructure
      "docker_language_server",
      "gh_actions_ls",
      "helm_ls",

      -- Template & Config
      "jinja_lsp",
      "spectral", -- OpenAPI
      "systemd_ls",
      "vacuum", -- OpenAPI

      -- General Purpose
      "lua_ls",
    },
  },
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    "neovim/nvim-lspconfig",
  },
}

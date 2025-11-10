-- Infrastructure as Code (IaC)
-- DevOps and IaC tooling: Terraform, Kubernetes, Docker, Ansible, Helm
--
-- Note: docker_language_server is installed via lsp.lua

return {
  -- Install IaC diagnostic tools
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "trivy", -- Container/IaC security scanner
        "kube-linter", -- Kubernetes linter
      },
    },
  },

  -- Configure Docker LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        docker_language_server = {
          settings = {
            docker = {
              languageserver = {
                formatter = {
                  ignoreMultilineInstructions = false,
                },
                diagnostics = {
                  -- Disable deprecated instruction warnings if needed
                  deprecatedMaintainer = "ignore",
                  directiveCasing = "warning",
                  emptyContinuationLine = "warning",
                  instructionCasing = "warning",
                  instructionCmdMultiple = "warning",
                  instructionEntrypointMultiple = "warning",
                  instructionHealthcheckMultiple = "warning",
                  instructionJSONInSingleQuotes = "warning",
                },
              },
            },
          },
        },
      },
    },
  },

  -- IaC-specific diagnostics and linters
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.diagnostics.kube_linter,
        nls.builtins.diagnostics.trivy,
      })
    end,
  },
}


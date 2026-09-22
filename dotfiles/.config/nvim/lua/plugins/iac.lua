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
        "actionlint", -- GitHub Actions linter
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
        nls.builtins.diagnostics.actionlint,
        nls.builtins.diagnostics.kube_linter,
      })
    end,
  },

  -- Terraform formatting on save; mirrors hk terraform builtin
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.terraform = { "terraform_fmt" }
      opts.formatters_by_ft["terraform-vars"] = { "terraform_fmt" }
    end,
  },
}

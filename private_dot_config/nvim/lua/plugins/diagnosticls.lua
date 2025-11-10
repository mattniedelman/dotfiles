-- diagnosticls configuration with KICS integration for IaC security scanning
-- KICS (Keeping Infrastructure as Code Secure) by Checkmarx
-- https://github.com/Checkmarx/kics

return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "mason.nvim",
    "mason-lspconfig.nvim",
  },
  opts = function(_, opts)
    local lspconfig = require("lspconfig")
    local util = require("lspconfig.util")

    -- Helper function to parse KICS JSON output
    local function parse_kics_output(output, bufnr)
      local diagnostics = {}
      local ok, result = pcall(vim.json.decode, output)

      if not ok or not result then
        return diagnostics
      end

      -- KICS JSON structure: { queries: [...], files: {...} }
      if result.queries then
        for _, query in ipairs(result.queries) do
          for _, file_result in ipairs(query.files or {}) do
            -- Map KICS severity to LSP diagnostic severity
            local severity = vim.diagnostic.severity.INFO
            if query.severity == "CRITICAL" or query.severity == "HIGH" then
              severity = vim.diagnostic.severity.ERROR
            elseif query.severity == "MEDIUM" then
              severity = vim.diagnostic.severity.WARN
            elseif query.severity == "LOW" then
              severity = vim.diagnostic.severity.INFO
            end

            table.insert(diagnostics, {
              lnum = (file_result.line or 1) - 1, -- LSP is 0-indexed
              col = 0,
              end_lnum = (file_result.line or 1) - 1,
              end_col = 0,
              severity = severity,
              source = "kics",
              message = string.format(
                "[%s] %s: %s",
                query.severity or "INFO",
                query.query_name or "Security Issue",
                query.description or file_result.issue_type or "No description"
              ),
              code = query.query_id,
              user_data = {
                platform = query.platform,
                category = query.category,
                cwe = query.cwe,
              },
            })
          end
        end
      end

      return diagnostics
    end

    -- KICS wrapper script path (we'll create this)
    local kics_wrapper = vim.fn.stdpath("config") .. "/scripts/kics-wrapper.sh"

    -- Configure diagnosticls with KICS
    lspconfig.diagnosticls.setup({
      cmd = { "diagnostic-languageserver", "--stdio" },
      filetypes = {
        -- Terraform / OpenTofu
        "terraform",
        "tf",
        "hcl",
        -- Kubernetes
        "yaml",
        "yml",
        -- Docker
        "dockerfile",
        -- CloudFormation / SAM
        "json",
        -- Ansible
        "yaml.ansible",
        -- Helm
        "helm",
      },
      root_dir = util.root_pattern(
        ".git",
        "terraform.tfvars",
        "*.tf",
        "*.yaml",
        "*.yml",
        "Dockerfile",
        "docker-compose.yml",
        "*.json"
      ),
      init_options = {
        linters = {
          kics = {
            command = kics_wrapper,
            debounce = 500,
            args = { "%filepath" },
            offsetLine = 0,
            offsetColumn = 0,
            sourceName = "kics",
            formatLines = 1,
            formatPattern = {
              "^(.*):(\\d+):(\\d+):\\s+\\[(\\w+)\\]\\s+(.*)$",
              {
                line = 2,
                column = 3,
                security = 4,
                message = 5,
              },
            },
            securities = {
              CRITICAL = "error",
              HIGH = "error",
              MEDIUM = "warning",
              LOW = "info",
              INFO = "hint",
            },
          },
        },
        filetypes = {
          terraform = "kics",
          tf = "kics",
          hcl = "kics",
          yaml = "kics",
          yml = "kics",
          dockerfile = "kics",
          json = "kics",
          ["yaml.ansible"] = "kics",
          helm = "kics",
        },
      },
      on_attach = function(client, bufnr)
        -- Diagnostic configuration
        vim.diagnostic.config({
          virtual_text = {
            prefix = "●",
            source = "if_many",
            spacing = 4,
          },
          signs = true,
          underline = true,
          update_in_insert = false,
          severity_sort = true,
          float = {
            source = "always",
            border = "rounded",
            header = "",
            prefix = "",
          },
        })

        -- Keymaps for diagnostics (only if not already set by LazyVim)
        local opts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "<leader>cq", vim.diagnostic.setloclist, opts)

        -- KICS-specific keymaps
        vim.keymap.set("n", "<leader>ck", function()
          vim.notify("Running KICS scan...", vim.log.levels.INFO)
          vim.cmd("LspRestart diagnosticls")
        end, { desc = "Run KICS scan", buffer = bufnr })
      end,
    })

    return opts
  end,
}


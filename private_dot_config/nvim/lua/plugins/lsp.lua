return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        awk_ls = {},
        bashls = {},
        dagger = {},
        diagnosticls = {},
        dockerls = {},
        golangci_lint_ls = {},
        gopls = {},
        gradle_ls = {},
        graphql = {},
        html = {},
        jdtls = {},
        jedi_language_server = {},
        pyright = {},
        ruff_lsp = {
          init_options = {
            settings = {
              args = {
                "--select",
                "ALL",
                "--ignore",
                -- B008: Do not perform function call {name} in argument defaults
                -- RET504: Unnecessary variable assignment before return statement
                -- COM: flake8-commas, deferring to black instead
                -- A003: Class attribute {name} is shadowing a python builtin
                -- ANN101: type annotations for `self`
                -- D212: Multiline docstrings should start on first line
                -- D400/D415: required punctuation at end of first docstring line
                -- UP: | vs typing.Union, list vs typing.List, etc.
                "B008,RET504,COM,A003,ANN101,D212,D400,D415,D,UP,N805,ANN,FA",
              },
            },
          },
        },
        sqlls = {},
        taplo = {},
        terraformls = {},
        yamlls = {
          settings = {
            yaml = {
              format = { enable = true, proseWrap = true },
              validate = true,
              completion = true,
              hover = true,
              editor = { tabSize = 4 },

              keyOrdering = false,
            },
          },
        },
      },
    },
  },
}

-- Code Completion & Snippets
-- Autocompletion engine and completion sources

return {
  {
    "saghen/blink.cmp",
    event = "InsertEnter", -- Load completion when entering insert mode
    dependencies = {
      { "Kaiser-Yang/blink-cmp-git" },
      { "bydlw98/blink-cmp-env" },
      { "disrupted/blink-cmp-conventional-commits" },
    },
    opts = {
      keymap = {
        preset = "enter",
      },
      sources = {
        default = {
          "conventional_commits",
          "lsp",
          "path",
          "snippets",
          "buffer",
          "git",
        },

        providers = {
          lsp = {
            transform_items = function(_, items)
              return vim.tbl_filter(function(item)
                return item.client_name ~= "Augment Server"
              end, items)
            end,
          },
          conventional_commits = {
            name = "Conventional Commits",
            module = "blink-cmp-conventional-commits",
            enabled = function()
              return vim.bo.filetype == "gitcommit"
            end,
            opts = {},
          },
          git = {
            module = "blink-cmp-git",
            name = "Git",
          },
          path = {
            opts = {
              get_cwd = function(_)
                return vim.fn.getcwd()
              end,
            },
          },
        },
        transform_items = function(_, items)
          return vim.tbl_filter(function(item)
            return item.kind ~= require("blink.cmp.types").CompletionItemKind.Snippet
          end, items)
        end,
      },

      signature = {
        enabled = true,
      },

      completion = {
        trigger = {
          show_on_keyword = true,
        },
        list = { selection = { preselect = false, auto_insert = false } },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 0,
        },
        ghost_text = { enabled = true, show_with_menu = true },

        menu = {
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "kind" },
            },
            treesitter = { "lsp" },
          },

          direction_priority = function()
            local ctx = require("blink.cmp").get_context()
            local item = require("blink.cmp").get_selected_item()
            if ctx == nil or item == nil then
              return { "s", "n" }
            end

            local item_text = item.textEdit ~= nil and item.textEdit.newText or item.insertText or item.label
            local is_multi_line = item_text:find("\n") ~= nil

            -- after showing the menu upwards, we want to maintain that direction
            -- until we re-open the menu, so store the context id in a global variable
            if is_multi_line or vim.g.blink_cmp_upwards_ctx_id == ctx.id then
              vim.g.blink_cmp_upwards_ctx_id = ctx.id
              return { "n", "s" }
            end
            return { "s", "n" }
          end,
        },
      },
    },
  },
}


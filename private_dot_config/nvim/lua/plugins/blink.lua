-- return {
--   "Saghen/blink.cmp",
--   version = "1.*",
--   optional = true,
--   specs = {
--     { "Saghen/blink.compat", version = "*", lazy = true, opts = {} },
--   },
--   opts = function(_, opts)
--     -- disable snippets
--     opts.sources.transform_items = function(_, items)
--       return vim.tbl_filter(
--         function(item) return item.kind ~= require("blink.cmp.types").CompletionItemKind.Snippet end,
--         items
--       )
--     end
--
--     opts.sources = {
--       providers = {
--         path = {
--           opts = {
--             get_cwd = function(_) return vim.fn.getcwd() end,
--           },
--         },
--       },
--     }
--
--     if not opts.keymap then opts.keymap = {} end
--     opts.keymap["<Tab>"] = { "snippet_forward", "fallback" }
--     opts.keymap["<C-F>"] = {
--       function()
--         local copilot = require "copilot.suggestion"
--         if copilot.is_visible() then
--           copilot.accept()
--           return true
--         end
--       end,
--     }
--   end,
-- }
return {
  "Saghen/blink.cmp",
  version = "1.*",
  optional = true,
  specs = {
    { "Saghen/blink.compat", version = "*", lazy = true, opts = {} },
    {
      "AstroNvim/astrolsp",
      optional = true,
      opts = function(_, opts)
        opts.capabilities = require("blink.cmp").get_lsp_capabilities(opts.capabilities)

        -- disable AstroLSP signature help if `blink.cmp` is providing it
        local blink_opts = require("astrocore").plugin_opts "blink.cmp"
        if vim.tbl_get(blink_opts, "signature", "enabled") == true then
          if not opts.features then opts.features = {} end
          opts.features.signature_help = false
        end
      end,
    },
    {
      "folke/lazydev.nvim",
      optional = true,
      specs = {
        {
          "Saghen/blink.cmp",
          opts = function(_, opts)
            if pcall(require, "lazydev.integrations.blink") then
              return require("astrocore").extend_tbl(opts, {
                sources = {
                  -- add lazydev to your completion providers
                  default = { "lazydev" },
                  providers = {
                    lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
                  },
                },
              })
            end
          end,
        },
      },
    },
  },
  opts_extend = { "sources.default" },
  opts = {
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },

      transform_items = function(_, items)
        return vim.tbl_filter(
          function(item) return item.kind ~= require("blink.cmp.types").CompletionItemKind.Snippet end,
          items
        )
      end,
    },

    keymap = {
      ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-N>"] = { "select_next", "show" },
      ["<C-P>"] = { "select_prev", "show" },
      ["<C-J>"] = { "select_next", "fallback" },
      ["<C-K>"] = { "select_prev", "fallback" },
      ["<C-U>"] = { "scroll_documentation_up", "fallback" },
      ["<C-D>"] = { "scroll_documentation_down", "fallback" },
      ["<C-e>"] = { "hide", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
      ["<Tab>"] = { "snippet_forward", "fallback" },
      ["<C-F>"] = {
        function()
          local copilot = require "copilot.suggestion"
          if copilot.is_visible() then
            copilot.accept()
            return true
          end
        end,
      },
    },
    completion = {
      list = { selection = { preselect = false, auto_insert = true } },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 0,
      },
    },
  },
}

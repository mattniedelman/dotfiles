return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "default",
      -- ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      -- ["<C-e>"] = { "hide", "fallback" },
      -- ["<CR>"] = { "accept", "fallback" },
      --
      -- ["<Tab>"] = { "snippet_forward", "fallback" },
      -- ["<S-Tab>"] = { "snippet_backward", "fallback" },
      --
      -- ["<Up>"] = { "select_prev", "fallback" },
      -- ["<Down>"] = { "select_next", "fallback" },
      -- ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
      -- ["<C-n>"] = { "select_next", "fallback_to_mappings" },
      --
      -- ["<C-b>"] = { "scroll_documentation_up", "fallback" },
      -- ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      --
      -- ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
      -- ["<C-F>"] = {
      --   function()
      --     local copilot = require("copilot.suggestion")
      --     if copilot.is_visible() then
      --       copilot.accept()
      --       return true
      --     end
      --   end,
      -- },
    },
    completion = {
      menu = {
        auto_show = false,
      },
      --   list = {
      --     selection = {
      --       preselect = false,
      --       auto_insert = true,
      --     },
      --   },
    },
  },
}

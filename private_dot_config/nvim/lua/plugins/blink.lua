return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "enter",
      ["<C-F>"] = {
        function()
          local copilot = require("copilot.suggestion")
          if copilot.is_visible() then
            copilot.accept()
            return true
          end
        end,
      },
    },
    completion = {
      list = {
        selection = {
          preselect = false,
          auto_insert = true,
        },
      },
    },
  },
}

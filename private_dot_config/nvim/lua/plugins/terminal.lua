-- Terminal & REPL Integration
-- External process interaction and REPL support

return {
  {
    "https://github.com/fresh2dev/zellij.vim",
    lazy = false,
  },
  {
    "jpalardy/vim-slime",
    cmd = { "SlimeSend", "SlimeSendCurrentLine" }, -- Load on first REPL command
    keys = {
      { "<C-c><C-c>", mode = { "n", "x" }, desc = "Send to REPL" },
    },
    config = function()
      vim.g.slime_target = "kitty"
      vim.g.slime_preserve_curpos = 0
      vim.g.slime_bracketed_paste = 1
    end,
  },
}


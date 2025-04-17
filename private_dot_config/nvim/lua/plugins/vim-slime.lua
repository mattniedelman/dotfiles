return {
  {
    "jpalardy/vim-slime",
    config = function()
      vim.g.slime_target = "kitty"
      vim.g.slime_preserve_curpos = 0
      vim.g.slime_bracketed_paste = 1
    end,
  },
  -- { "klafyvel/vim-slime-cells", dependencies = { "jpalardy/vim-slime" }, config = function()
  --
  -- end },
}

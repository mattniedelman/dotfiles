return {
  {
    "iamcco/markdown-preview.nvim",
    config = function()
      vim.g.mkdp_theme = "light"
      vim.g.mkdp_preview_options = {
        content_editable = false,
        disable_filename = true,
      }
    end,
  },
}

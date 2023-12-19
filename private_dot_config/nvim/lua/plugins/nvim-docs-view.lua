return {
  {
    "amrbashir/nvim-docs-view",
    config = function()
      require("docs-view").setup({
        position = "bottom",
        height = 80,
      })
    end,
  },
}

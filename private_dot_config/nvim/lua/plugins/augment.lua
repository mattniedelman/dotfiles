-- vim.g.augment_workspace_folders = { "~/git/imprivata" }
vim.g.augment_workspace_folders = { require("lazyvim.util").root() }
vim.g.augment_disable_tab_mapping = true

return {
  "augmentcode/augment.vim",
  branch = "main",
  lazy = false,
}

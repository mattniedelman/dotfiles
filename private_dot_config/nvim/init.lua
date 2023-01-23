require('plugins')

vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])

vim.o.shortmess = vim.o.shortmess .. "c"

vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false

vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.signcolumn = 'number'

vim.o.completeopt = "menuone,noselect"

vim.g.mapleader = ' '
vim.keymap.set('', '<leader>sv', ':source $MYVIMRC<CR>', { desc = 'Reload Vim config' })

vim.keymap.set({ 'i', 'v' }, 'fd', '<ESC>', { desc = 'Exit chord' })
vim.keymap.set({ 'i', 'v', 'n' }, '<C-a>', '<ESC>^', { desc = 'Beginning of line' })
vim.keymap.set({ 'i', 'v', 'n' }, '<C-e>', '<ESC>$', { desc = 'End of line' })


vim.keymap.set({ 'n', 'x' }, 'cp', '"+y')
vim.keymap.set({ 'n', 'x' }, 'cv', '"+p')

vim.keymap.set('', 'q', '<nop>')
vim.keymap.set('', 'Q', '<nop>')

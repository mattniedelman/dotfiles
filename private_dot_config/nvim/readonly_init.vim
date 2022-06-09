
set nocompatible
let g:polyglot_is_disabled = {}

call plug#begin()
  Plug 'kyazdani42/nvim-web-devicons'
  Plug 'folke/trouble.nvim'
  "Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
  Plug 'hashivim/vim-terraform'
  Plug 'jpalardy/vim-slime'
  Plug 'neovim/nvim-lspconfig'
  Plug 'dense-analysis/ale'
  "Plug 'sheerun/vim-polyglot'
  Plug 'ntpeters/vim-better-whitespace'
  Plug 'arcticicestudio/nord-vim'
  Plug 'google/vim-maktaba'
  Plug 'google/vim-codefmt'
  Plug 'google/vim-glaive'
  Plug 'neovim/nvim-lspconfig'

  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/cmp-path'
  Plug 'hrsh7th/cmp-cmdline'
  Plug 'hrsh7th/nvim-cmp'
  Plug 'hrsh7th/cmp-vsnip'
  Plug 'hrsh7th/vim-vsnip'

  Plug 'tpope/vim-fugitive'
call plug#end()

" trouble.nvim {{{
lua << EOF
require("trouble").setup {
  position = "right",
  auto_open = false,
  use_diagnostic_signs = true
  }
EOF
" }}}
" markdown-preview.nvim {{{
let g:mkdp_auto_close = 1
let g:mkdp_auto_start = 0
let g:mkdp_browser = "firefox"
let g:mkdp_theme = 'light'
let g:mkdp_page_title = '${name}'
" }}}

" vim-terraform {{{
let g:terraform_align = 1
let g:terraform_fmt_on_save = 1
" }}}

" vim-slime {{{
let g:slime_target = "tmux"
let g:slime_python_ipython = 1
let g:slime_default_config = {"socket_name": "default", "target_pane": "{last}"}
" }}}
"

" }}}
" nvim-lspconfig {{{
lua << EOF
  servers = {
    "angularls",
    "ansiblels",
    "bashls",
    "csharp_ls",
    "cssls",
    "cssmodules_ls",
    "diagnosticls",
    "dockerls",
    "eslint",
    "gopls",
    "gradle_ls",
    "html",
    "jsonls",
    "prosemd_lsp",
    "spectral",
    "taplo",
    "tsserver",
    "vimls",
    "rnix",
    "pyright",
    "pylsp",
    "yamlls"
  }
  local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
  for _, lsp in ipairs(servers) do
    require'lspconfig'[lsp].setup{capabilities = capabilities}
  end

EOF

" }}}
" ale {{{
let g:ale_disable_lsp = 1

" }}}
" vim-polyglot {{{
let g:polyglot_disabled = ['cue']

" }}}
" vim-better-whitespace {{{
let g:better_whitespace_enabled = 1
let g:strip_whitespace_on_save = 1
let g:strip_whitespace_confirm = 0

" }}}
" nord-vim {{{
set background=dark
set termguicolors
colorscheme nord
" }}}

" vim-codefmt {{{
function! ApplyPythonFormatters() abort
	execute 'FormatCode black'
	execute 'FormatCode isort'
endfunction
augroup autoformat_settings
autocmd FileType bzl AutoFormatBuffer buildifier
autocmd FileType c,cpp,proto,javascript,arduino AutoFormatBuffer clang-format
autocmd FileType dart AutoFormatBuffer dartfmt
autocmd FileType go AutoFormatBuffer gofmt
autocmd FileType gn AutoFormatBuffer gn
autocmd FileType html,css,sass,scss,less,json AutoFormatBuffer js-beautify
autocmd FileType java AutoFormatBuffer google-java-format
autocmd FileType rust AutoFormatBuffer rustfmt
autocmd FileType vue AutoFormatBuffer prettier
autocmd FileType nix AutoFormatBuffer nixpkgs-fmt
augroup END

augroup autoformat
	autocmd!
	autocmd BufWritePre *.py call ApplyPythonFormatters() | noautocmd write
augroup END
" }}}
noremap Q <nop>
noremap q <nop>
imap fd <ESC>
vmap fd <ESC>
map <C-a> <ESC>^
imap <C-a> <ESC>^i
map <C-e> <ESC>$
imap <C-e> <ESC>$a
nmap <S-Enter> O<ESC>
nmap <CR> o<ESC>
set nofoldenable
set smartcase
set ignorecase
set clipboard=unnamedplus


set number
set hidden
set nobackup
set nowritebackup
set cmdheight=2
set updatetime=300
set shortmess+=c

set smarttab
set tabstop=4
set shiftwidth=4

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("nvim-0.5.0") || has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

autocmd BufNewFile,BufRead *.cue setf cue
autocmd BufNewFile,BufRead *.md setlocal textwidth=80

set completeopt=menu,menuone,noselect

lua <<EOF
  -- Setup nvim-cmp.
  local cmp = require'cmp'

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      end,
    },
    window = {
      -- completion = cmp.config.window.bordered(),
      -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<tab>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'vsnip' }, -- For vsnip users.
      -- { name = 'luasnip' }, -- For luasnip users.
      -- { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    }, {
      { name = 'buffer' },
    })
  })

  -- Set configuration for specific filetype.
  cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
      { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    }, {
      { name = 'buffer' },
    })
  })

  -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

  -- Setup lspconfig.
EOF

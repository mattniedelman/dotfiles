call plug#begin()

  " Plug 'google/vim-maktaba'
  " Plug 'google/vim-codefmt'

  " Plug 'google/vim-glaive'

  """"

  Plug 'kyazdani42/nvim-web-devicons'
  Plug 'arcticicestudio/nord-vim'

  Plug 'fladson/vim-kitty'
  Plug 'knubie/vim-kitty-navigator', {'do': 'cp ./*.py ~/.config/kitty/'}

  Plug 'jpalardy/vim-slime'

  Plug 'dense-analysis/ale'
  Plug 'folke/trouble.nvim'
  Plug 'neovim/nvim-lspconfig'
  Plug 'ntpeters/vim-better-whitespace'

  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/cmp-cmdline'
  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'hrsh7th/cmp-path'
  Plug 'hrsh7th/cmp-vsnip'
  Plug 'hrsh7th/nvim-cmp'
  Plug 'hrsh7th/vim-vsnip'

  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-sleuth'

  Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }
  Plug 'mzlogin/vim-markdown-toc'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-lua/popup.nvim'
  Plug 'nvim-telescope/telescope-media-files.nvim'
  Plug 'nvim-telescope/telescope-symbols.nvim'
  Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

  Plug 'mfussenegger/nvim-dap'
  Plug 'williamboman/mason.nvim'
  Plug 'williamboman/mason-lspconfig.nvim'
  Plug 'jose-elias-alvarez/null-ls.nvim'
  Plug 'jayp0521/mason-null-ls.nvim'
  Plug 'lukas-reineke/lsp-format.nvim'

  Plug 'fatih/vim-go'
  Plug 'someone-stole-my-name/yaml-companion.nvim'
call plug#end()

let mapleader = "\<Space>"


lua << EOF
require('telescope').load_extension('media_files')
require('telescope').load_extension('yaml_schema')
EOF

let g:polyglot_is_disabled = {}
set autoindent
set backspace=indent,eol,start
set clipboard=unnamedplus
set cmdheight=2
set complete-=i
set mouse=a
set hidden
set ignorecase
set nobackup
set nofoldenable
set nowritebackup
set number
set shiftwidth=4
set shortmess+=c
set smartcase
set noswapfile
set smarttab
set tabstop=4
set updatetime=300

au FocusGained,BufEnter * :silent! !

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


" mason.nvim {{{
lua << EOF
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = {
        "awk_ls",
        "dagger",
        "diagnosticls",
        "dockerls",
        "eslint",
        "gopls",
        "graphql",
        "html",
        "jsonls",
        "quick_lint_js",
        "tsserver",
        "texlab",
        "marksman",
        "prosemd_lsp",
        "prismals",
        "pylsp",
        "ruby_ls",
        "sqlls",
        "sqls",
        "stylelint_lsp",
        "terraformls",
        "tflint",
        "tsserver",
        "vimls",
        "lemminx",
        "yamlls"
    }
})

local null_ls = require 'null-ls'
require("mason-null-ls").setup({
    ensure_installed = {
        "hadolint",
        "gofumpt",
        "goimports",
        "goimports_reviser",
        "golangci_lint",
        "golines",
        "revive",
        "staticcheck",
        "fixjson",
        "jq",
        "black",
        "flake8",
        "isort",
        "mypy",
        "pylint",
        "vulture",
        "shellcheck",
        "shellharden",
        "shfmt",
        "sqlfluff",
        "sql_formatter",
        "taplo",
        "vint",
        "yamlft",
        "yamllint"
    }
})

require("mason-null-ls").setup_handlers({
  jq = function()
    null_ls.register(null_ls.builtins.formatting.jq)
  end

})
EOF

" jupytext.vim {{{
let g:jupytext_fmt = 'py'
" }}}

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
let g:mkdp_browser = 'firefox'
let g:mkdp_theme = 'light'
let g:mkdp_page_title = '${name}'
" }}}

" vim-terraform {{{
let g:terraform_align = 1
let g:terraform_fmt_on_save = 1
" }}}

" vim-slime {{{
let g:slime_target = 'kitty'
let g:slime_python_ipython = 1
" }}}
"

" }}}
" nvim-lspconfig {{{
lua << EOF
  require("lsp-format").setup()
  servers = require("mason-lspconfig").get_installed_servers()
  local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
  for _, lsp in ipairs(servers) do
    require'lspconfig'[lsp].setup{capabilities = capabilities, on_attach=require("lsp-format").on_attach}
  end

EOF
" }}}
"
" yaml-companion.nvim {{{
lua << EOF
local cfg = require("yaml-companion").setup({
  -- Built in file matchers
  builtin_matchers = {
    -- Detects Kubernetes files based on content
    kubernetes = { enabled = true },
  },

  -- Additional schemas available in Telescope picker
  schemas = {
    result = {
      {
        name = "eksctl",
        uri = "https://raw.githubusercontent.com/weaveworks/eksctl/b440775877e40c73614a00c4dc1688351c15b3f9/pkg/apis/eksctl.io/v1alpha5/assets/schema.json"
      }
      --{
      --  name = "Kubernetes 1.22.4",
      --  uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.22.4-standalone-strict/all.json",
      --},
    },
  },

  -- Pass any additional options that will be merged in the final LSP config
  lspconfig = {
    flags = {
      debounce_text_changes = 150,
    },
    settings = {
      redhat = { telemetry = { enabled = false } },
      yaml = {
        validate = true,
        format = { enable = true },
        hover = true,
        schemaStore = {
          enable = true,
          url = "https://www.schemastore.org/api/json/catalog.json",
        },
        schemaDownload = { enable = true },
        schemas = {},
        trace = { server = "debug" },
      },
    },
  },
})
require("lspconfig")["yamlls"].setup(cfg)
EOF
" }}}
" ale {{{
let g:ale_disable_lsp = 1

" }}}
" vim-polyglot {{{
let g:polyglot_disabled = ['cue']

" }}}
" vim-better-whitespace {{{
let g:better_whitespace_enabled=1
let g:show_spaces_that_precede_tabs=1
let g:strip_whitelines_at_eof=1
let g:strip_whitespace_confirm = 0
let g:strip_whitespace_on_save = 1

" }}}
" nord-vim {{{
set background=dark
set termguicolors
colorscheme nord
" }}}

" vim-codefmt {{{
" function! ApplyPythonFormatters() abort
" 	execute 'FormatCode black'
" 	execute 'FormatCode isort'
" endfunction
" augroup autoformat_settings
" autocmd FileType bzl AutoFormatBuffer buildifier
" autocmd FileType c,cpp,proto,javascript,arduino AutoFormatBuffer clang-format
" autocmd FileType dart AutoFormatBuffer dartfmt
" autocmd FileType go AutoFormatBuffer gofmt
" autocmd FileType gn AutoFormatBuffer gn
" autocmd FileType html,css,sass,scss,less,json AutoFormatBuffer js-beautify
" autocmd FileType java AutoFormatBuffer google-java-format
" autocmd FileType rust AutoFormatBuffer rustfmt
" autocmd FileType vue AutoFormatBuffer prettier
" autocmd FileType nix AutoFormatBuffer nixpkgs-fmt
" augroup END

" augroup autoformat
" 	autocmd!
" 	autocmd BufWritePre *.py call ApplyPythonFormatters() | noautocmd write
" augroup END
" }}}

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

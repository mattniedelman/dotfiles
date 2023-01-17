call plug#begin()
  Plug 'sheerun/vim-polyglot'
  Plug 'hrsh7th/vim-vsnip'
  Plug 'nvim-tree/nvim-web-devicons'
  Plug 'hrsh7th/nvim-compe'
  Plug 'ray-x/lsp_signature.nvim'

  Plug 'petobens/poet-v'
  Plug 'arcticicestudio/nord-vim'

  Plug 'fladson/vim-kitty'

  Plug 'jpalardy/vim-slime'

  Plug 'dense-analysis/ale'
  Plug 'folke/trouble.nvim'
  Plug 'neovim/nvim-lspconfig'
  Plug 'ntpeters/vim-better-whitespace'

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
nnoremap <Leader>sv :source $MYVIMRC<CR>

lua << EOF
require('telescope').load_extension('media_files')
require('telescope').load_extension('yaml_schema')
EOF

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
set shortmess+=c
set smartcase
set noswapfile
set updatetime=300

set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent


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

let g:python3_host_prog='/home/mattniedelman/.cache/pypoetry/virtualenvs/neovim-0WD0XgmR-py3.10/bin/python'
" poet-v
let g:poetv_executables = ['poetry']
let g:poetv_auto_activate = 1
"

" mason.nvim {{{
lua << EOF
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "awk_ls",
    "dagger",
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
    "prismals",
    "pylsp",
    "ruby_ls",
    "sqlls",
    "sqls",
    "terraformls",
    "tflint",
    "tsserver",
    "vimls",
    "lemminx",
    "yamlls"
  },
  automatic_installation = true,
  automatic_setup = true
})

local null_ls = require("null-ls")

null_ls.setup({
  sources = {
   --null_ls.builtins.code_actions.gitsigns,
   --null_ls.builtins.code_actions.refactoring,
   --null_ls.builtins.code_actions.shellcheck,
   --null_ls.builtins.diagnostics.actionlint,
   --null_ls.builtins.diagnostics.checkmake,
   --null_ls.builtins.diagnostics.fish,
   --null_ls.builtins.diagnostics.mypy.with({ prefer_local = '.venv/bin' }),
   --null_ls.builtins.diagnostics.flake8,
   --null_ls.builtins.diagnostics.ruff,
   --null_ls.builtins.diagnostics.pylama,
   --null_ls.builtins.diagnostics.pylint,
   null_ls.builtins.formatting.isort,
   null_ls.builtins.formatting.black,
   --null_ls.builtins.diagnostics.hadolint,
    --null_ls.builtins.diagnostics,
    --null_ls.builtins.formatting,
    --null_ls.builtins.hover,
    --null_ls.builtins.completion
    }
  }
)

require("mason-null-ls").setup({
  automatic_installation=true,
  automatic_setup= {
    exclude = {
      "textlint",
      "misspell",
      "cspell"
      }
    },
  ensure_installed = nil
})

--require('mason-null-ls').setup_handlers()

require('lspconfig').pylsp.setup({
--  settings = {
    pylsp = {
      plugins = {
        flake8 = {
          enabled = True,
          maxLineLength = 88,
        },
        jedi_completion = {
          include_class_objects = false,
          include_function_objects = false,
        }
      }
    }
--  }
})
require('lspconfig').pyright.setup({
  settings = {
    python = {
      venvPath = ".venv"
    }
  }
})

require("lsp_signature").setup({
  wrap=false,
  max_height = nil,
  max_width = nil,
})

require("lsp_signature").status_line(200)

require("lsp-format").setup()
servers = require("mason-lspconfig").get_installed_servers()
for _, lsp in ipairs(servers) do
  require'lspconfig'[lsp].setup{on_attach=require("lsp-format").on_attach}
end
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
"
" yaml-companion.nvim {{{
lua << EOF
local cfg = require("yaml-companion").setup({
  builtin_matchers = {
    kubernetes = { enabled = true },
  },
  schemas = {
    result = {
      {
        name = "eksctl",
        uri = "https://raw.githubusercontent.com/weaveworks/eksctl/b440775877e40c73614a00c4dc1688351c15b3f9/pkg/apis/eksctl.io/v1alpha5/assets/schema.json"
      }
    },
  },
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

" nvim-compe {{{
lua << EOF
vim.o.completeopt = "menuone,noselect"
require'compe'.setup {
  enabled = true;
  autocomplete = true;
  debug = false;
  min_length = 1;
  preselect = 'enable';
  throttle_time = 80;
  source_timeout = 200;
  resolve_timeout = 800;
  incomplete_delay = 400;
  max_abbr_width = 100;
  max_kind_width = 100;
  max_menu_width = 100;
  documentation = {
    border = { '', '' ,'', ' ', '', '', '', ' ' }, -- the border option is the same as `|help nvim_open_win|`
    winhighlight = "NormalFloat:CompeDocumentation,FloatBorder:CompeDocumentationBorder",
    max_width = 120,
    min_width = 60,
    max_height = math.floor(vim.o.lines * 0.3),
    min_height = 1,
  };

  source = {
    path = true;
    buffer = true;
    nvim_lsp = true;
    vsnip = true;
  };
}
local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-n>"
  elseif vim.fn['vsnip#available'](1) == 1 then
    return t "<Plug>(vsnip-expand-or-jump)"
  elseif check_back_space() then
    return t "<Tab>"
  else
    return vim.fn['compe#complete']()
  end
end
_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-p>"
  elseif vim.fn['vsnip#jumpable'](-1) == 1 then
    return t "<Plug>(vsnip-jump-prev)"
  else
    -- If <S-Tab> is not working in your terminal, change it to <C-h>
    return t "<S-Tab>"
  end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
EOF

inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm('<CR>')
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })


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
autocmd! BufNewFile,BufRead Dvcfile,*.dvc,dvc.lock setfiletype yaml

call plug#begin()
  Plug 'kyazdani42/nvim-web-devicons'
  Plug 'folke/trouble.nvim'
  "Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
  Plug 'hashivim/vim-terraform'
  Plug 'jpalardy/vim-slime'
  Plug 'neovim/nvim-lspconfig'
  Plug 'dense-analysis/ale'
  Plug 'sheerun/vim-polyglot'
  Plug 'ntpeters/vim-better-whitespace'
  Plug 'arcticicestudio/nord-vim'
  Plug 'google/vim-maktaba'
  Plug 'google/vim-codefmt'
  Plug 'google/vim-glaive'
call plug#end()

" trouble.nvim {{{
lua << EOF
require("trouble").setup {
  position = "right",
  auto_open = true,
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
  for _, lsp in ipairs(servers) do
    require'lspconfig'[lsp].setup{}
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
augroup autoformat_settings
autocmd FileType bzl AutoFormatBuffer buildifier
autocmd FileType c,cpp,proto,javascript,arduino AutoFormatBuffer clang-format
autocmd FileType dart AutoFormatBuffer dartfmt
autocmd FileType go AutoFormatBuffer gofmt
autocmd FileType gn AutoFormatBuffer gn
autocmd FileType html,css,sass,scss,less,json AutoFormatBuffer js-beautify
autocmd FileType java AutoFormatBuffer google-java-format
autocmd FileType python AutoFormatBuffer black
" Alternative: autocmd FileType python AutoFormatBuffer autopep8
autocmd FileType rust AutoFormatBuffer rustfmt
autocmd FileType vue AutoFormatBuffer prettier
autocmd FileType nix AutoFormatBuffer nixpkgs-fmt
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
set nocompatible
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


" " nvim-compe {{{
" set completeopt=menuone,noselect
" lua << EOF
" -- Compe setup
" require'compe'.setup {
"   enabled = true;
"   autocomplete = true;
"   debug = false;
"   min_length = 1;
"   preselect = 'enable';
"   throttle_time = 80;
"   source_timeout = 200;
"   incomplete_delay = 400;
"   max_abbr_width = 100;
"   max_kind_width = 100;
"   max_menu_width = 100;
"   documentation = true;

"   source = {
"     path = true;
"    nvim_lsp = true;
"   };
" }

" local t = function(str)
"   return vim.api.nvim_replace_termcodes(str, true, true, true)
" end

" local check_back_space = function()
"     local col = vim.fn.col('.') - 1
"     if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
"         return true
"     else
"         return false
"     end
" end

" -- Use (s-)tab to:
" --- move to prev/next item in completion menuone
" --- jump to prev/next snippet's placeholder
" _G.tab_complete = function()
"   if vim.fn.pumvisible() == 1 then
"     return t "<C-n>"
"   elseif check_back_space() then
"     return t "<Tab>"
"   else
"     return vim.fn['compe#complete']()
"   end
" end
" _G.s_tab_complete = function()
"   if vim.fn.pumvisible() == 1 then
"     return t "<C-p>"
"   else
"     return t "<S-Tab>"
"   end
" end

" vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
" vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
" vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
" vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})

" --This line is important for auto-import
" vim.api.nvim_set_keymap('i', '<cr>', 'compe#confirm("<cr>")', { expr = true })
" vim.api.nvim_set_keymap('i', '<c-space>', 'compe#complete()', { expr = true })
" EOF

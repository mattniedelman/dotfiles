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
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-sleuth'

  Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }
  Plug 'kyazdani42/nvim-web-devicons'
  Plug 'mzlogin/vim-markdown-toc'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-lua/popup.nvim'
  Plug 'nvim-telescope/telescope-media-files.nvim'
  Plug 'nvim-telescope/telescope-symbols.nvim'
  Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

  Plug 'goerz/jupytext.vim'

  Plug 'renerocksai/calendar-vim'
  Plug 'renerocksai/telekasten.nvim'
call plug#end()

let mapleader = "\<Space>"

lua << EOF
require('telescope').load_extension('media_files')
EOF

let g:polyglot_is_disabled = {}

set autoindent
set autoread
set autowrite
set backspace=indent,eol,start
set clipboard=unnamedplus
set cmdheight=2
set complete-=i
set hidden
set ignorecase
set mouse=a
set nobackup
set nocompatible
set nofoldenable
set noswapfile
set nowritebackup
set number
set shiftwidth=4
set shortmess+=c
set smartcase
set smarttab
set tabstop=4
set updatetime=300
set incsearch
set hlsearch
set ignorecase
set smartcase
set lazyredraw
set nocursorcolumn
set nocursorline
set wrap
set textwidth=80
set formatoptions=qrn1

set notimeout
set ttimeout
set ttimeoutlen=10
set timeoutlen=500
set signcolumn=yes
command! -nargs=* -complete=help Help vertical belowright help <args>
autocmd FileType help wincmd L


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

" jupytext.vim {{{
let g:jupytext_fmt = "py"
" }}}
" telekasten.nim {{{
nnoremap <leader>zf :lua require('telekasten').find_notes()<CR>
nnoremap <leader>zd :lua require('telekasten').find_daily_notes()<CR>
nnoremap <leader>zg :lua require('telekasten').search_notes()<CR>
nnoremap <leader>zz :lua require('telekasten').follow_link()<CR>

" on hesitation, bring up the panel
nnoremap <leader>z :lua require('telekasten').panel()<CR>
lua << EOF
local home = vim.fn.expand("~/notes")
require('telekasten').setup({
    home         = home,
    take_over_my_home = true,
    auto_set_filetype = true,
    dailies      = home .. '/' .. 'daily',
    weeklies     = home .. '/' .. 'weekly',
    templates    = home .. '/' .. 'templates',
    image_subdir = "img",
    extension    = ".md",
    new_note_filename = "title",
    -- file uuid type ("rand" or input for os.date()")
    uuid_type = "%Y%m%d%H%M",
    -- UUID separator
    uuid_sep = "-",

    -- following a link to a non-existing note will create it
    follow_creates_nonexisting = true,
    dailies_create_nonexisting = true,
    weeklies_create_nonexisting = true,

    -- skip telescope prompt for goto_today and goto_thisweek
    journal_auto_open = false,

    -- template for new notes (new_note, follow_link)
    -- set to `nil` or do not specify if you do not want a template
    template_new_note = home .. '/' .. 'templates/new_note.md',

    -- template for newly created daily notes (goto_today)
    -- set to `nil` or do not specify if you do not want a template
    template_new_daily = home .. '/' .. 'templates/daily.md',

    -- template for newly created weekly notes (goto_thisweek)
    -- set to `nil` or do not specify if you do not want a template
    template_new_weekly= home .. '/' .. 'templates/weekly.md',

    -- image link style
    -- wiki:     ![[image name]]
    -- markdown: ![](image_subdir/xxxxx.png)
    image_link_style = "markdown",

    -- default sort option: 'filename', 'modified'
    sort = "filename",

    -- integrate with calendar-vim
    plug_into_calendar = true,
    calendar_opts = {
        -- calendar week display mode: 1 .. 'WK01', 2 .. 'WK 1', 3 .. 'KW01', 4 .. 'KW 1', 5 .. '1'
        weeknm = 4,
        -- use monday as first day of week: 1 .. true, 0 .. false
        calendar_monday = 1,
        -- calendar mark: where to put mark for marked days: 'left', 'right', 'left-fit'
        calendar_mark = 'left-fit',
    },

    -- telescope actions behavior
    close_after_yanking = false,
    insert_after_inserting = true,

    -- tag notation: '#tag', ':tag:', 'yaml-bare'
    tag_notation = "#tag",

    -- command palette theme: dropdown (window) or ivy (bottom panel)
    command_palette_theme = "ivy",

    -- tag list theme:
    -- get_cursor: small tag list at cursor; ivy and dropdown like above
    show_tags_theme = "ivy",

    -- when linking to a note in subdir/, create a [[subdir/title]] link
    -- instead of a [[title only]] link
    subdirs_in_links = true,

    -- template_handling
    -- What to do when creating a new note via `new_note()` or `follow_link()`
    -- to a non-existing note
    -- - prefer_new_note: use `new_note` template
    -- - smart: if day or week is detected in title, use daily / weekly templates (default)
    -- - always_ask: always ask before creating a note
    template_handling = "smart",

    -- path handling:
    --   this applies to:
    --     - new_note()
    --     - new_templated_note()
    --     - follow_link() to non-existing note
    --
    --   it does NOT apply to:
    --     - goto_today()
    --     - goto_thisweek()
    --
    --   Valid options:
    --     - smart: put daily-looking notes in daily, weekly-looking ones in weekly,
    --              all other ones in home, except for notes/with/subdirs/in/title.
    --              (default)
    --
    --     - prefer_home: put all notes in home except for goto_today(), goto_thisweek()
    --                    except for notes with subdirs/in/title.
    --
    --     - same_as_current: put all new notes in the dir of the current note if
    --                        present or else in home
    --                        except for notes/with/subdirs/in/title.
    new_note_location = "smart",

    -- should all links be updated when a file is renamed
    rename_update_links = true,

    vaults = {
        vault2 = {
            -- alternate configuration for vault2 here. Missing values are defaulted to
            -- default values from telekasten.
            -- e.g.
            -- home = "/home/user/vaults/personal",
        },
    },

    -- how to preview media files
    -- "telescope-media-files" if you have telescope-media-files.nvim installed
    -- "catimg-previewer" if you have catimg installed
    media_previewer = "telescope-media-files",
})
EOF
" }}}
"
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

" -*- mode: vimrc -*-
" vim: ft=vim

call plug#begin(stdpath('config') . '/plugged')
  Plug 'jeffkreeftmeijer/vim-numbertoggle'
  Plug 'ntpeters/vim-better-whitespace'

  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'

  Plug 'lifepillar/vim-solarized8'
  Plug 'fatih/vim-go'
  Plug 'pearofducks/ansible-vim'
  Plug 'wakatime/vim-wakatime'
  Plug 'jpalardy/vim-slime'
  Plug 'Yggdroot/indentline'
  Plug 'tommcdo/vim-lion'
  Plug 'tpope/vim-sensible'
  Plug 'tpope/vim-commentary'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'sheerun/vim-polyglot'
  Plug 'airblade/vim-gitgutter'
  Plug 'dense-analysis/ale'
  Plug 'sbdchd/neoformat'
  Plug 'previm/previm'

call plug#end()

" Reloads vimrc after saving but keep cursor position
if !exists('*ReloadVimrc')
   fun! ReloadVimrc()
       let save_cursor = getcurpos()
       source resolve(expand($MYVIMRC))
       call setpos('.', save_cursor)
   endfun
endif
autocmd! BufWritePost resolve(expand($MYVIMRC)) call ReloadVimrc()

function FileConfigs()
  au FileType vim setlocal ts=2 sts=2 sw=2 expandtab

  au BufNewFile,BufRead *.yml,*.yaml setlocal expandtab ts=2 sw=2

  let g:better_whitespace_enabled=1
  let g:strip_whitespace_on_save=1
  let g:strip_whitespace_confirm=0

"  augroup fmt
"    autocmd!
"    autocmd BufWritePre * undojoin | Neoformat
"  augroup END

endfunction

function Keymap()
  " Q is super annoying to me
  noremap Q <nop>
  noremap q <nop>

  " My preferred chord to get back to normal mode
  imap fd <ESC>
  vmap fd <ESC>

  map <C-a> <ESC>^
  imap <C-a> <ESC>^i

  map <C-e> <ESC>$
  imap <C-e> <ESC>$a

  nmap <S-Enter> O<ESC>
  nmap <CR> o<ESC>
endfunction

function UserConfig()
  let g:previm_enable_realtime=1
  let g:vim_markdown_conceal=0
  let g:vim_markdown_conceal_code_blocks=0
  let g:previm_open_cmd="google-chrome"
  let g:airline_theme="solarized"
  set background=dark
  set termguicolors
  colorscheme solarized8_flat

  set nocompatible

  " Makes copy/paste work
  set clipboard+=unnamedplus

  set noerrorbells
  set noswapfile
  set nowritebackup
  set number
  set showcmd

  set splitright
  set splitbelow

  set ignorecase
  set smartcase

  set wrap
  set mouse=a

endfunction

call UserConfig()
call FileConfigs()
call Keymap()

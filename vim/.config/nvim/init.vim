" *- mode: vimrc -*-
"vim: ft=vim

function! Layers()
" Configuration Layers declaration.
" Add layers with `Layer '+layername'` and add individual packages
" with `ExtraPlugin 'githubUser/Repo'`.

  Layer '+core/behavior'
  Layer '+core/sensible'
  Layer '+completion/nvim-completion-manager' " Or '+completion/deoplete'
  Layer '+completion/snippets'
  Layer '+checkers/ale' " Or '+checkers/neomake'
  Layer '+checkers/quickfix'
  Layer '+gui/ide'
  Layer '+nav/buffers'
  Layer '+nav/comments'
  Layer '+nav/files'
  Layer '+nav/fzf'
  Layer '+nav/quit'
  Layer '+nav/start-screen'
  Layer '+nav/jump'
  Layer '+nav/text'
  Layer '+nav/tmux'
  Layer '+nav/windows'
  Layer '+scm/git'
  Layer '+specs/testing'
  Layer '+tools/language-server'
  Layer '+tools/multicursor'
  Layer '+tools/terminal'
  Layer '+tools/format'
  Layer '+ui/airline'
  Layer '+ui/toggles'

  " Language layers.
  Layer '+lang/python'
  Layer '+lang/vim'

  " Additional plugins.
  ExtraPlugin 'jeffkreeftmeijer/vim-numbertoggle'
  ExtraPlugin 'ntpeters/vim-better-whitespace'
  ExtraPlugin 'vim-airline/vim-airline-themes'
  ExtraPlugin 'lifepillar/vim-solarized8'
  ExtraPlugin 'tpope/vim-surround'
endfunction

function! UserInit()
" This block is called at the very startup of Spaceneovim initialization
" before layers configuration.
endfunction

function! UserConfig()
" This block is called after Spaceneovim layers are configured.
  noremap Q <nop>
  noremap q <nop>
  imap fd <ESC>

  map <C-a> <ESC>^
  imap <C-a> <ESC>^i

  map <C-e> <ESC>$
  imap <C-e> <ESC>$a

  set invcursorline
  set wrap
  set textwidth=80
  set formatoptions=qrn1

  set autoindent
  set complete-=i
  set showmatch
  set smarttab
  set et
  set tabstop=4
  set shiftwidth=4
  set expandtab

  set number relativenumber

  if exists('+colorcolumn')
      set colorcolumn=80
  else
      au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
  endif

  let g:better_whitespace_enabled=1
  let g:strip_whitespace_on_save=1

  SetThemeWithBg 'dark', 'solarized8_dark_flat', 'solarized'
  let g:airline_powerline_fonts=1
  if !exists('g:airline_symbols')
    let g:airline_symbols={}
  endif

endfunction

" Do NOT remove these calls!
call spaceneovim#init()
call Layers()
call UserInit()
call spaceneovim#bootstrap()
call UserConfig()

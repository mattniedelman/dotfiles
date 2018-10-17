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
  ExtraPlugin 'docker/docker'
  ExtraPlugin 'fatih/vim-go'
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
  vmap fd <ESC>

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

  let g:NERDSpaceDelims=1
  let g:NERDCompactSexyComs=1
  let g:NERDDefaultAlign='left'


  SetThemeWithBg 'dark', 'solarized8_dark_flat', 'solarized'
  let g:airline_powerline_fonts=1
  if !exists('g:airline_symbols')
    let g:airline_symbols={}
  endif

  let g:neoformat_python_black = {
    \ 'exe': 'black',
    \ 'stdin': 1,
    \ 'args': ['-l 80', '--quiet', '-' ]}

  let g:neoformat_enabled_python = ['autopep8', 'yapf', 'black']

  let g:neoformat_enabled_yaml = ['']

  " Enable alignment
  let g:neoformat_basic_format_align = 1

  " Enable tab to spaces conversion
  let g:neoformat_basic_format_retab = 1

  " Enable trimmming of trailing whitespace
  let g:neoformat_basic_format_trim = 1

endfunction

" Do NOT remove these calls!
call spaceneovim#init()
call Layers()
call UserInit()
call spaceneovim#bootstrap()
call UserConfig()

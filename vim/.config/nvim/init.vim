" *- mode: vimrc -*-
"vim: ft=vim

function! Layers()
  " Configuration Layers declaration.
  " Add layers with `Layer '+layername'` and add individual packages
  " with `ExtraPlugin 'githubUser/Repo'`.

  Layer '+core/behavior'
  Layer '+core/sensible'
  Layer '+completion/deoplete'
  Layer '+checkers/ale' " Or '+checkers/neomake'
  Layer '+checkers/syntastic'
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
  ExtraPlugin 'fatih/vim-go'
  ExtraPlugin 'pearofducks/ansible-vim'
  ExtraPlugin 'majutsushi/tagbar'
  ExtraPlugin 'wakatime/vim-wakatime'
  ExtraPlugin 'google/vim-jsonnet'
  ExtraPlugin 'jpalardy/vim-slime'
  ExtraPlugin 'SirVer/ultisnips'
  ExtraPlugin 'honza/vim-snippets'
  ExtraPlugin 'Yggdroot/indentline'
  ExtraPlugin 'raphamorim/lucario'
endfunction

function! UserInit()
  " This block is called at the very startup of Spaceneovim initialization
  " before layers configuration.
endfunction

function! UserConfig()
  SetThemeWithBg 'dark', 'solarized8_dark_flat', 'solarized'
  colorscheme solarized8
  " This block is called after Spaceneovim layers are configured.
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

  nmap " ysiW"
  nmap ' ysiW'

  nnoremap <A-a> <C-a>
  nnoremap <A-x> <C-x>

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


  let g:airline_powerline_fonts=1
  if !exists('g:airline_symbols')
    let g:airline_symbols={}
  endif

  let g:neoformat_run_all_formatters=1
  let g:neoformat_python_black = {
        \ 'exe': 'black',
        \ 'stdin': 1,
        \ 'args': ['-l 79', '--quiet', '-' ]}
  let g:neoformat_python_isort = {
        \ 'exe': 'isort',
        \ 'stdin': 1,
        \ 'args': ['-', '-tc', '-up']}

  let g:neoformat_enabled_python = ['black', 'isort']

  let g:neoformat_starlark_black = g:neoformat_python_black
  let g:neoformat_enabled_starlark = ['black']

  let g:neoformat_sh_shfmt = {
        \ 'exe': 'shfmt',
        \ 'stdin': 1,
        \ 'args': ['-i', '2', '-ci']}
  let g:neoformat_enabled_sh = ['shfmt']

  let g:neoformat_yaml_prettier = {
        \ 'exe': 'prettier',
        \ 'stdin': 1,
        \ 'args': ['--quote-props', 'preserve', '--parser', 'yaml', '--no-bracket-spacing']}
  let g:neoformat_enabled_yaml = ['prettier']

  let g:neoformat_enabled_dockerfile = ['']

  " Enable alignment
  " let g:neoformat_basic_format_align = 1

  " Enable tab to spaces conversion
  " let g:neoformat_basic_format_retab = 1

  " Enable trimmming of trailing whitespace
  let g:neoformat_basic_format_trim = 1

  set tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab
  au! BufNewFile,BufReadPost *.{yaml,yml} set filetype=yaml indentkeys-=0# indentkeys-=<:>
  " autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
  autocmd FileType make setlocal noexpandtab
  set clipboard+=unnamedplus

  au BufNewFile,BufReadPost Tiltfile set filetype=starlark
  au  FileType starlark set syntax=python

  let g:go_def_mode='gopls'
  let g:go_info_mode='gopls'
  " Launch gopls when Go files are in use
  let g:LanguageClient_serverCommands.go = ['gopls']
  " Run gofmt on save
  autocmd BufWritePre *.go :call LanguageClient#textDocument_formatting_sync()

  let g:slime_target="tmux"
  let g:slime_python_ipython=1
  let g:UltiSnipsExpandTrigger="<tab>"
  let g:UltiSnipsJumpForwardTrigger="<c-b>"
  let g:UltiSnipsJumpBackwardTrigger="<c-z>"
endfunction

" Do NOT remove these calls!
call spaceneovim#init()
call Layers()
call UserInit()
call spaceneovim#bootstrap()
call UserConfig()

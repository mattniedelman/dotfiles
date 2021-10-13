{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    withNodeJs = true;
    withPython3 = true;
    extraPackages = [
      pkgs.lua5_1
      pkgs.lua51Packages.luaffi
    ];
    extraConfig = ''
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
      set clipboard+=unnamedplus


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
    '';

    plugins = with pkgs.vimPlugins; [
      {
        plugin = trouble-nvim;
        config = ''
          lua << EOF
          require("trouble").setup {}
          EOF
        '';
      }
      {
        plugin = markdown-preview-nvim;
        config = ''
          let g:mkdp_auto_close = 0
          let g:mkdp_auto_start = 1
          let g:mkdp_browser = "firefox"
        '';
      }
      nvim-treesitter-pyfold
      nvim-treesitter-refactor
      {
        plugin = nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars);
      }
      neovim-sensible
      telescope-nvim
      vim-wakatime
      fzf-vim
      vim-airline-themes
      vim-gitgutter
      vim-commentary
      vim-numbertoggle
      nvim-web-devicons
      popup-nvim
      plenary-nvim
      vim-cue
      {
        plugin = vim-slime;
        config = ''
          let g:slime_python_ipython = 1
          let g:slime_target = "tmux"
        '';
      }
      {
        plugin = nvim-compe;
        config = ''
          set completeopt=menuone,noselect
          lua << EOF
          -- Compe setup
          require'compe'.setup {
            enabled = true;
            autocomplete = true;
            debug = false;
            min_length = 1;
            preselect = 'enable';
            throttle_time = 80;
            source_timeout = 200;
            incomplete_delay = 400;
            max_abbr_width = 100;
            max_kind_width = 100;
            max_menu_width = 100;
            documentation = true;

            source = {
              path = true;
              nvim_lsp = true;
            };
          }

          local t = function(str)
            return vim.api.nvim_replace_termcodes(str, true, true, true)
          end

          local check_back_space = function()
              local col = vim.fn.col('.') - 1
              if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                  return true
              else
                  return false
              end
          end

          -- Use (s-)tab to:
          --- move to prev/next item in completion menuone
          --- jump to prev/next snippet's placeholder
          _G.tab_complete = function()
            if vim.fn.pumvisible() == 1 then
              return t "<C-n>"
            elseif check_back_space() then
              return t "<Tab>"
            else
              return vim.fn['compe#complete']()
            end
          end
          _G.s_tab_complete = function()
            if vim.fn.pumvisible() == 1 then
              return t "<C-p>"
            else
              return t "<S-Tab>"
            end
          end

          vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
          vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
          vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
          vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})

          --This line is important for auto-import
          vim.api.nvim_set_keymap('i', '<cr>', 'compe#confirm("<cr>")', { expr = true })
          vim.api.nvim_set_keymap('i', '<c-space>', 'compe#complete()', { expr = true })
          EOF
        '';
      }
      {
        plugin = nvim-lspconfig;
        config = ''
          lua << EOF
            servers = {
              "bashls",
              "diagnosticls",
              "dockerls",
              "gopls",
              "jsonls",
              "rnix",
              "pyright",
              "vimls",
              "yamlls"
            }
            for _, lsp in ipairs(servers) do
              require'lspconfig'[lsp].setup{}
            end

            require'lspconfig'.jdtls.setup{ cmd = { 'jdtls' } }
          EOF
        '';
      }
      {
        plugin = ale;
        config = ''
          let g:ale_disable_lsp = 1
        '';
      }
      {
        plugin = vim-polyglot;
        config = ''
          let g:polyglot_disabled = ['cue']
        '';
      }
      {
        plugin = vim-better-whitespace;
        config = ''
          let g:better_whitespace_enabled = 1
          let g:strip_whitespace_on_save = 1
          let g:strip_whitespace_confirm = 0
        '';
      }
      {
        plugin = nord-vim;
        config = ''
          set background=dark
          set termguicolors
          colorscheme nord
        '';
      }
      {
        plugin = vim-codefmt;
        config = ''
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
        '';
      }
    ];
  };
}

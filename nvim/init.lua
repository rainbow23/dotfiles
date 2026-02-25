-- ① lazy.nvim bootstrap
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ② leader を先に設定（lazy.nvim のキーマップ定義より前に必要）
vim.g.mapleader = ' '

-- ③ プラグイン定義
require('lazy').setup({
  -- FZF
  { 'junegunn/vim-easy-align',   lazy = false },
  { 'junegunn/fzf',     dir = '~/.fzf', build = './install --bin', lazy = false },
  { 'junegunn/fzf.vim', lazy = false, dependencies = { 'junegunn/fzf' } },
  { 'junegunn/vim-peekaboo',     lazy = false },
  -- Unite
  { 'Shougo/unite.vim',          lazy = false },
  { 'rainbow23/unite-session',   lazy = false },
  { 'Shougo/neomru.vim',         lazy = false },
  { 'Shougo/unite-outline',      lazy = false },
  { 'Shougo/vimproc.vim',        build = 'make', lazy = false },
  -- Denops / DDC
  { 'Shougo/deol.nvim',          lazy = false },
  { 'Shougo/ddc.vim',            lazy = false },
  { 'Shougo/ddc-ui-native',      lazy = false },
  { 'Shougo/ddc-around',         lazy = false },
  { 'matsui54/ddc-buffer',       lazy = false },
  { 'tani/ddc-fuzzy',            lazy = false },
  -- UI
  { 'vim-airline/vim-airline',        lazy = false },
  { 'vim-airline/vim-airline-themes', lazy = false },
  { 'Yggdroot/indentLine',            lazy = false },
  { 'itchyny/vim-cursorword',         lazy = false },
  { 'itchyny/vim-parenmatch',         lazy = false },
  { 'machakann/vim-highlightedyank',  lazy = false },
  -- Clipboard / Yank
  { 'kana/vim-fakeclip',         lazy = false },
  { 'svermeulen/vim-easyclip',   lazy = false, init = function()
    vim.g.EasyClipShareYanks = 1
    vim.g.EasyClipUseGlobalPasteToggle = 0
  end },
  { 'leafcage/yankround.vim',    lazy = false },
  -- Cursor / Motion
  { 'terryma/vim-multiple-cursors',  lazy = false },
  { 'rhysd/accelerated-jk',         lazy = false },
  { 'easymotion/vim-easymotion',     lazy = false },
  { 'yuki-yano/fuzzy-motion.vim',    lazy = false },
  { 'rhysd/clever-f.vim',            lazy = false },
  { 'yuttie/comfortable-motion.vim', lazy = false },
  { 'matze/vim-move',                lazy = false },
  -- Search
  { 'rainbow23/vim-anzu',        lazy = false },
  { 'mileszs/ack.vim',           lazy = false },
  { 'thinca/vim-qfreplace',      lazy = false },
  { 't9md/vim-quickhl',          lazy = false },
  -- File / Buffer
  { 'preservim/nerdtree',             lazy = false },
  { 'jistr/vim-nerdtree-tabs',        lazy = false },
  { 'Xuyuanp/nerdtree-git-plugin',    lazy = false },
  { 'jlanzarotta/bufexplorer',        lazy = false, init = function() vim.g.bufExplorerDisableDefaultKeyMapping = 1 end },
  { 'ctrlpvim/ctrlp.vim',             lazy = false },
  { 'mattn/ctrlp-matchfuzzy',         lazy = false },
  { 'christoomey/vim-tmux-navigator', lazy = false },
  -- Bookmarks（既存）
  { 'rainbow23/vim-bookmarks', branch = 'fzf', lazy = false },
  -- Bookmarks（新規追加）
  {
    'heilgar/bookmarks.nvim',
    lazy = false,
    dependencies = {
      'kkharji/sqlite.lua',
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
    },
    build = function(plugin)
      -- storage.lua の初期スキーマに branch/list が欠けているバグへのワークアラウンド
      -- https://github.com/heilgar/bookmarks.nvim/issues/12
      local path = plugin.dir .. '/lua/bookmarks/storage.lua'
      local f = io.open(path, 'r')
      if not f then return end
      local content = f:read('*a')
      f:close()
      if not content:find('branch%s*=') then
        content = content:gsub(
          '(project_root%s*=%s*"text",)',
          '%1\n                branch       = "text",\n                list         = "text",'
        )
        local fw = io.open(path, 'w')
        if fw then
          fw:write(content)
          fw:close()
          vim.notify('bookmarks.nvim: storage.lua patched (branch/list added to schema)')
        end
      end
    end,
    config = function()
      require('bookmarks').setup({
        on_attach = function()
          local bm  = require('bookmarks')
          local map = vim.keymap.set
          map('n', 'mm', bm.bookmark_toggle, { desc = 'Bookmark toggle' })
          map('n', 'mi', bm.bookmark_ann,    { desc = 'Bookmark annotate' })
          map('n', 'mc', bm.bookmark_clean,  { desc = 'Bookmark clean' })
          map('n', 'mn', bm.bookmark_next,   { desc = 'Bookmark next' })
          map('n', 'mp', bm.bookmark_prev,   { desc = 'Bookmark prev' })
          map('n', 'ml', bm.bookmark_list,   { desc = 'Bookmark list' })
        end,
      })
    end,
  },
  -- Git
  { 'tpope/vim-fugitive',          lazy = false },
  { 'tpope/vim-rhubarb',           lazy = false },
  { 'airblade/vim-gitgutter',      lazy = false },
  { 'iberianpig/tig-explorer.vim', lazy = false },
  { 'rbgrouleff/bclose.vim',       lazy = false },
  -- Edit
  { 'preservim/nerdcommenter',          lazy = false },
  { 'machakann/vim-sandwich',           lazy = false },
  { 'tpope/vim-surround',               lazy = false },
  { 'tpope/vim-repeat',                 lazy = false },
  { 'jiangmiao/auto-pairs',             lazy = false },
  { 'ntpeters/vim-better-whitespace',   lazy = false },
  { 'kana/vim-operator-user',           lazy = false },
  { 'kana/vim-operator-replace',        lazy = false, dependencies = { 'kana/vim-operator-user' } },
  -- Snippet / Completion
  { 'rainbow23/vim-snippets', lazy = false },
  { 'Shougo/neco-syntax',     lazy = false },
  -- LSP
  { 'prabirshrestha/vim-lsp',    lazy = false },
  { 'prabirshrestha/async.vim',  lazy = false },
  { 'mattn/vim-lsp-settings',    lazy = false },
  { 'shun/ddc-source-vim-lsp',   lazy = false },
  { 'lighttiger2505/sqls.vim',   lazy = false },
  -- Go
  { 'fatih/vim-go',        build = ':GoUpdateBinaries', lazy = false },
  { 'mdempsky/gocode',     rtp = 'vim', lazy = false },
  { 'mattn/vim-goimports', lazy = false },
  -- JSON / HTML
  { 'elzr/vim-json',      lazy = false },
  { 'alvan/vim-closetag', lazy = false },
  -- Util
  { 'majutsushi/tagbar',          lazy = false },
  { 'tyru/current-func-info.vim', lazy = false },
  { 'regedarek/ZoomWin',          lazy = false },
  { 'vimlab/split-term.vim',      lazy = false },
  { 'osyo-manga/unite-quickfix',  lazy = false },
  { 'ujihisa/unite-colorscheme',  lazy = false },
  -- Denops plugins
  { 'vim-denops/denops.vim',               lazy = false },
  { 'vim-denops/denops-shared-server.vim', lazy = false },
  { 'vim-denops/denops-helloworld.vim',    lazy = false },
  { 'lambdalisue/kensaku.vim',             lazy = false },
  { 'lambdalisue/kensaku-search.vim',      lazy = false },
  { 'vim-skk/skkeleton',                   lazy = false },
})

-- ④ VimScript 設定を source（プラグインロード後）
vim.cmd('source ' .. vim.fn.expand('~/dotfiles/_vimrc'))

-- ⑤ nvim 向け上書き設定
-- autochdir を無効化: bookmarks.nvim が getcwd() を project_root として使うため
-- autochdir が有効だとファイルごとに project_root が変わり複数ファイルのブックマークが表示されない
vim.opt.autochdir = false

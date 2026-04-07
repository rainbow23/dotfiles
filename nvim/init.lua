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
  -- Bookmarks
  {
    'heilgar/bookmarks.nvim',
    lazy = false,
    dependencies = {
      'kkharji/sqlite.lua',
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
    },
    init = function()
      -- storage.lua の初期スキーマに branch/list が欠けているバグへのワークアラウンド
      -- build はインストール時のみ実行されるため init（毎起動・プラグインロード前）で対応
      -- https://github.com/heilgar/bookmarks.nvim/issues/12
      local plugin_dir = vim.fn.stdpath('data') .. '/lazy/bookmarks.nvim'
      local path = plugin_dir .. '/lua/bookmarks/storage.lua'
      local f = io.open(path, 'r')
      if not f then return end
      local content = f:read('*a')
      f:close()
      if not content:find('branch%s*=%s*"text"') then
        content = content:gsub(
          '(project_root%s*=%s*"text",)',
          '%1\n                branch       = "text",\n                list         = "text",'
        )
        local fw = io.open(path, 'w')
        if fw then
          fw:write(content)
          fw:close()
        end
      end
      -- パッチ済みファイルを git の変更検知から除外（lazy.nvim の sync エラーを防ぐ）
      vim.fn.system({'git', '-C', plugin_dir, 'update-index', '--assume-unchanged', 'lua/bookmarks/storage.lua'})
    end,
    config = function()
      -- Esc でウィンドウを閉じる（_vimrc の noremap <ESC> による上書きを回避）
      require('telescope').setup({
        defaults = {
          mappings = {
            i = { ['<esc>'] = require('telescope.actions').close },
            n = { ['<esc>'] = require('telescope.actions').close },
          },
        },
      })
      require('bookmarks').setup({})
      local autocmds = require('bookmarks.autocmds')
      local map      = vim.keymap.set
      local function refresh()
        autocmds.refresh_buffer(vim.api.nvim_get_current_buf())
      end
      map('n', 'mm', function()
        require('bookmarks.commands').add_bookmark()
        refresh()
      end, { desc = 'Bookmark toggle' })
      map('n', 'mc', function()
        require('bookmarks.commands').remove_bookmark()
        refresh()
      end, { desc = 'Bookmark remove' })
      map('n', 'mn', function()
        local bufnr = vim.api.nvim_get_current_buf()
        require('bookmarks.navigation').jump_to_next(autocmds.get_buffer_bookmarks(bufnr))
      end, { desc = 'Bookmark next' })
      map('n', 'mp', function()
        local bufnr = vim.api.nvim_get_current_buf()
        require('bookmarks.navigation').jump_to_prev(autocmds.get_buffer_bookmarks(bufnr))
      end, { desc = 'Bookmark prev' })
      map('n', 'ml', function()
        require('telescope').extensions.bookmarks.list()
      end, { desc = 'Bookmark list' })
      -- Nerd Font 非対応環境での ? 表示を回避するため ASCII 文字に上書き
      vim.fn.sign_define('BookmarkSign', {
        text   = '>>',
        texthl = 'BookmarkSignHighlight',
        numhl  = 'BookmarkSignHighlight',
        linehl = 'BookmarkHighlight',
      })
      -- _vimrc の colorscheme 適用で BookmarkHighlight が消えるため再定義
      -- VimEnter: _vimrc source 完了後に確実に定義、ColorScheme: 以降の変更にも対応
      local function restore_bookmark_hl()
        vim.api.nvim_set_hl(0, 'BookmarkHighlight',     { bg = '#594d3e', bold = true })
        vim.api.nvim_set_hl(0, 'BookmarkSignHighlight', { fg = '#FFE5B4', bold = true })
        vim.api.nvim_set_hl(0, 'TelescopeSelection',    { bg = '#87CEEB', fg = '#000000', bold = true })
        require('bookmarks.autocmds').refresh_all_buffers()
      end
      vim.api.nvim_create_autocmd({ 'VimEnter', 'ColorScheme' }, {
        callback = restore_bookmark_hl,
      })
    end,
  },
  -- Git
  { 'tpope/vim-fugitive',          lazy = false },
  { 'tpope/vim-rhubarb',           lazy = false },
  { 'airblade/vim-gitgutter',      lazy = false },
  { 'iberianpig/tig-explorer.vim', lazy = false },
  { 'rbgrouleff/bclose.vim',       lazy = false },
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    lazy = false,
    config = function()
      require('toggleterm').setup()
      local Terminal = require('toggleterm.terminal').Terminal
      local tig = Terminal:new({
        cmd = 'tig',
        direction = 'float',
        float_opts = { border = 'curved' },
        on_open = function() vim.cmd('startinsert!') end,
      })
      vim.keymap.set('n', '<leader>tig', function() tig:toggle() end, { desc = 'tig float' })
    end,
  },
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

-- Search / SearchFromCurrDir を telescope に置き換え
-- File モード: ファイル名を fuzzy 検索 / Grep モード: ファイル内文字列を live grep
-- <C-t> で両モード切り替え（クエリ文字列を引き継ぐ）
-- _vimrc の fzf 版は has('nvim') で無効化済み
local conf         = require('telescope.config').values
local finders      = require('telescope.finders')
local pickers      = require('telescope.pickers')
local make_entry   = require('telescope.make_entry')
local sorters      = require('telescope.sorters')
local actions      = require('telescope.actions')
local action_state = require('telescope.actions.state')

local make_file_search
local make_grep_search

local open_in_tab = function(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if entry then
    vim.cmd('tabedit ' .. (entry.path or entry.filename or entry.value))
  end
end

make_file_search = function(opts)
  pickers.new(opts, {
    prompt_title = (opts.base_title or 'Search') .. ' [File]  <C-g>=Grep  <C-t>=新規タブ',
    finder = finders.new_oneshot_job(opts.files_cmd, {
      entry_maker = make_entry.gen_from_file(opts),
      cwd         = opts.cwd,
    }),
    previewer = conf.file_previewer(opts),
    sorter    = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      local switch = function()
        local query = action_state.get_current_line()
        actions.close(prompt_bufnr)
        make_grep_search(vim.tbl_extend('force', opts, { default_text = query }))
      end
      map('i', '<C-g>', switch)
      map('n', '<C-g>', switch)
      map('i', '<C-t>', open_in_tab)
      map('n', '<C-t>', open_in_tab)
      return true
    end,
  }):find()
end

make_grep_search = function(opts)
  local grep_args  = vim.tbl_flatten({ conf.vimgrep_arguments, opts.additional_args or {} })
  local grep_entry = make_entry.gen_from_vimgrep(opts)

  pickers.new(opts, {
    prompt_title = (opts.base_title or 'Search') .. ' [Grep]  <C-g>=File  <C-t>=新規タブ',
    finder = finders.new_job(function(prompt)
      if not prompt or prompt == '' then return nil end
      local cmd = vim.deepcopy(grep_args)
      table.insert(cmd, '--')
      table.insert(cmd, prompt)
      return cmd
    end, grep_entry, nil, opts.cwd),
    previewer = conf.grep_previewer(opts),
    sorter    = sorters.empty(),
    attach_mappings = function(prompt_bufnr, map)
      local switch = function()
        local query = action_state.get_current_line()
        actions.close(prompt_bufnr)
        make_file_search(vim.tbl_extend('force', opts, { default_text = query }))
      end
      map('i', '<C-g>', switch)
      map('n', '<C-g>', switch)
      map('i', '<C-t>', open_in_tab)
      map('n', '<C-t>', open_in_tab)
      return true
    end,
  }):find()
end

vim.api.nvim_create_user_command('Search', function(opts)
  local git_root = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
  make_file_search({
    cwd             = git_root,
    default_text    = opts.args,
    additional_args = { '--hidden', '--smart-case', '-g', '!.git/', '-g', '!.claude/' },
    files_cmd       = { 'rg', '--files', '--hidden', '--color=never', '-g', '!.git/', '-g', '!.claude/' },
    base_title      = 'Search (git root)',
  })
end, { nargs = '*', bang = true })

vim.api.nvim_create_user_command('SearchFromCurrDir', function(opts)
  make_file_search({
    cwd             = vim.fn.getcwd(),
    default_text    = opts.args,
    additional_args = { '--hidden', '--smart-case', '-g', '!.claude/' },
    files_cmd       = { 'rg', '--files', '--hidden', '--color=never', '-g', '!.claude/' },
    base_title      = 'Search (cwd)',
  })
end, { nargs = '*', bang = true })

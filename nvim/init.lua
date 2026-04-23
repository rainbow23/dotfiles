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
        local bufnr = vim.api.nvim_get_current_buf()
        local line = vim.api.nvim_win_get_cursor(0)[1]
        local list = autocmds.get_buffer_bookmarks(bufnr)
        local is_bookmarked = false
        if list then
          for _, bm in ipairs(list.items) do
            if bm.line == line then
              is_bookmarked = true
              break
            end
          end
        end
        if is_bookmarked then
          require('bookmarks.commands').remove_bookmark()
        else
          require('bookmarks.commands').add_bookmark()
        end
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
        local function getTitleName()
            local bm_config = require('bookmarks').get_config()
            local title = '📖 Bookmarks'
            if bm_config.use_branch_specific then
              local branch = require('bookmarks.utils').get_current_branch()
              title = title .. (branch and string.format(' (branch: %s)', branch) or ' (branch: unknown)')
            end
            local active_list = bm_config.active_list or 'default'
            if active_list == 'all' then
              title = title .. ' [🔍 all lists]'
            elseif active_list == 'default' then
              title = title .. ' [📋 default]'
            else
              title = title .. string.format(' [📁 %s]', active_list)
            end
            title = title .. '  <C-d>=削除'
            return title
        end

        require('telescope').extensions.bookmarks.list({
          prompt_title = getTitleName(),
          layout_strategy = 'horizontal',
          layout_config = {
            height = 0.9,
            width = 0.9,
            preview_width = 0.6,
            prompt_position = 'bottom',
          },
          attach_mappings = function(prompt_bufnr, map)
            local function delete_bookmark()
              local as = require('telescope.actions.state')
              local current_picker = as.get_current_picker(prompt_bufnr)
              local selection = as.get_selected_entry()
              if not (selection and selection.value) then return end
              local bmk = selection.value
              local bm_config = require('bookmarks').get_config()
              local branch = nil
              if bm_config.use_branch_specific then
                branch = require('bookmarks.utils').get_current_branch()
              end
              require('bookmarks.storage').remove_bookmark(bmk.filename, bmk.line, bmk.project_root, branch, bmk.list)
              local bufnr = vim.fn.bufnr(bmk.filename)
              if bufnr ~= -1 then
                require('bookmarks.autocmds').refresh_buffer(bufnr)
              end
              current_picker:delete_selection(function()
                vim.notify('Bookmark deleted', vim.log.levels.INFO)
              end)
            end
            map('i', '<C-d>', delete_bookmark)
            map('n', '<C-d>', delete_bookmark)
            return true
          end,
        })
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
local actions        = require('telescope.actions')
local action_state   = require('telescope.actions.state')
local layout_actions = require('telescope.actions.layout')
local builtin        = require('telescope.builtin')

local open_in_split = function(prompt_bufnr, cmd)
  local entry = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  if entry then
    vim.cmd(cmd .. ' ' .. (entry.path or entry.filename or entry.value))
  end
end

local make_attach_mappings = function(preview_default_on, extra_mappings)
  return function(prompt_bufnr, map)
    if not preview_default_on then
      vim.schedule(function() layout_actions.toggle_preview(prompt_bufnr) end)
    end
    map('i', '<C-h>', function(b) open_in_split(b, 'split') end)
    map('n', '<C-h>', function(b) open_in_split(b, 'split') end)
    map('i', '<C-f>', layout_actions.toggle_preview)
    map('n', '<C-f>', layout_actions.toggle_preview)
    if extra_mappings then extra_mappings(prompt_bufnr, map) end
    return true
  end
end

local file_search_shortcut = '<C-r>=MRU <C-b>=Buffers <C-f>=Preview <C-t>=新規タブ <C-v>=vsplit <C-h>=hsplit'
local grep_search_shortcut = '<C-f>=Preview <C-t>=新規タブ <C-v>=vsplit <C-h>=hsplit'

local make_file_search  -- forward declaration

local open_oldfiles_with_back = function(file_opts)
  builtin.oldfiles({
    prompt_title = 'Old Files  <C-r>=FileSearchに戻る',
    attach_mappings = function(prompt_bufnr, map)
      map('i', '<C-r>', function(b)
        actions.close(b)
        vim.schedule(function() make_file_search(file_opts) end)
      end)
      map('n', '<C-r>', function(b)
        actions.close(b)
        vim.schedule(function() make_file_search(file_opts) end)
      end)
      return true
    end,
  })
end

local open_buffers_with_back = function(file_opts)
  builtin.buffers({
    prompt_title = 'Buffers  <C-b>=FileSearchに戻る',
    attach_mappings = function(prompt_bufnr, map)
      map('i', '<C-b>', function(b)
        actions.close(b)
        vim.schedule(function() make_file_search(file_opts) end)
      end)
      map('n', '<C-b>', function(b)
        actions.close(b)
        vim.schedule(function() make_file_search(file_opts) end)
      end)
      return true
    end,
  })
end

make_file_search = function(opts)
  pickers.new(opts, {
    prompt_title = (opts.base_title or 'FileSearch') .. ' [File] ' .. file_search_shortcut,
    finder = finders.new_oneshot_job(opts.files_cmd, {
      entry_maker = make_entry.gen_from_file(opts),
      cwd         = opts.cwd,
    }),
    previewer = conf.file_previewer(opts),
    sorter    = conf.file_sorter(opts),
    attach_mappings = make_attach_mappings(false, function(bufnr, map)
      map('i', '<C-r>', function(b)
        actions.close(b)
        vim.schedule(function() open_oldfiles_with_back(opts) end)
      end)
      map('n', '<C-r>', function(b)
        actions.close(b)
        vim.schedule(function() open_oldfiles_with_back(opts) end)
      end)
      map('i', '<C-b>', function(b)
        actions.close(b)
        vim.schedule(function() open_buffers_with_back(opts) end)
      end)
      map('n', '<C-b>', function(b)
        actions.close(b)
        vim.schedule(function() open_buffers_with_back(opts) end)
      end)
    end),
  }):find()
end

local make_grep_search = function(opts)
  local grep_args  = vim.tbl_flatten({ conf.vimgrep_arguments, opts.additional_args or {} })
  local grep_entry = make_entry.gen_from_vimgrep(opts)

  pickers.new(opts, {
    prompt_title = (opts.base_title or 'Search') .. ' [Grep] ' .. grep_search_shortcut,
    finder = finders.new_job(function(prompt)
      if not prompt or prompt == '' then return nil end
      local cmd = vim.deepcopy(grep_args)
      table.insert(cmd, '--')
      table.insert(cmd, prompt)
      return cmd
    end, grep_entry, nil, opts.cwd),
    previewer = conf.grep_previewer(opts),
    sorter    = sorters.empty(),
    attach_mappings = make_attach_mappings(true),
  }):find()
end

vim.api.nvim_create_user_command('FileSearch', function(opts)
  local git_root = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
  make_file_search({
    cwd       = git_root,
    default_text = opts.args,
    files_cmd = { 'rg', '--files', '--hidden', '--color=never', '-g', '!.git/', '-g', '!.claude/' },
    base_title = 'FileSearch (git root)',
  })
end, { nargs = '*', bang = true })

vim.api.nvim_create_user_command('GrepSearch', function(opts)
  local git_root = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
  make_grep_search({
    cwd             = git_root,
    default_text    = opts.args,
    additional_args = { '--hidden', '--smart-case', '-g', '!.git/', '-g', '!.claude/' },
    base_title      = 'GrepSearch (git root)',
  })
end, { nargs = '*', bang = true })

vim.api.nvim_create_user_command('BLines', function(opts)
  builtin.current_buffer_fuzzy_find({ default_text = opts.args })
end, { nargs = '*', bang = true })

vim.api.nvim_create_user_command('GitStatus', function(opts)
  builtin.git_status({ default_text = opts.args })
end, { nargs = '*', bang = true })

vim.api.nvim_create_user_command('FileSearchFromCurrDir', function(opts)
  make_file_search({
    cwd       = vim.fn.getcwd(),
    default_text = opts.args,
    files_cmd = { 'rg', '--files', '--hidden', '--color=never', '-g', '!.claude/' },
    base_title = 'FileSearch (cwd)',
  })
end, { nargs = '*', bang = true })

-- UI ハイライト（colorscheme 適用後に再定義）
local function restore_ui_hl()
  vim.api.nvim_set_hl(0, 'TelescopeSelection', { bg = '#87CEEB', fg = '#000000', bold = true })
  vim.api.nvim_set_hl(0, 'TabLineSel',         { bg = '#87CEEB', fg = '#000000', bold = true })
end
vim.api.nvim_create_autocmd({ 'VimEnter', 'ColorScheme' }, { callback = restore_ui_hl })

-- タブラインにファイル名のみ表示する
function _G.MyTabLine()
  local s = ''
  for i = 1, vim.fn.tabpagenr('$') do
    s = s .. (i == vim.fn.tabpagenr() and '%#TabLineSel#' or '%#TabLine#')
    s = s .. '%' .. i .. 'T'
    local bufnr = vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]
    local name  = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t')
    if name == '' then name = '[No Name]' end
    s = s .. ' ' .. name .. ' '
  end
  return s .. '%#TabLineFill#%T'
end
vim.opt.tabline = '%!v:lua.MyTabLine()'

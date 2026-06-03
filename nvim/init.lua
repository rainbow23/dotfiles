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

-- telescope picker 内で <C-l> レイアウト切替を行う関数を生成する
-- layouts: { { layout_strategy, layout_config }, ... } の順に循環する
-- require は呼び出し時に解決するため lazy.setup() より前に定義可
local telescope_layout_presets = {
  { layout_strategy = 'horizontal', layout_config = { height = 0.9, width = 0.9, preview_width  = 0.4, prompt_position = 'bottom' } },
  { layout_strategy = 'vertical',   layout_config = { height = 0.9, width = 0.9, preview_height = 0.4, prompt_position = 'bottom', preview_cutoff = 1 } },
}
local function make_layout_toggle(prompt_bufnr, layouts)
  layouts = layouts or telescope_layout_presets
  local idx = 1  -- プリセット[1]=horizontal が初期状態なので、最初のトグルで[2]=vertical に切り替わる
  return function()
    local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
    idx = (idx % #layouts) + 1
    local lyt = layouts[idx]
    picker.layout_strategy = lyt.layout_strategy
    picker.layout_config   = lyt.layout_config
    picker.previewer = picker.all_previewers and picker.all_previewers[picker.current_previewer_index or 1]
    local ok, err = pcall(function() picker:full_layout_update() end)
    if not ok then vim.notify('layout error: ' .. tostring(err), vim.log.levels.ERROR) end
  end
end

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

      -- navigation.lua パッチ: project_root を getcwd() から git root に統一
      local nav_path = plugin_dir .. '/lua/bookmarks/navigation.lua'
      local fnav = io.open(nav_path, 'r')
      if fnav then
        local nav_src = fnav:read('*a')
        fnav:close()
        if not nav_src:find('git rev%-parse') then
          nav_src = nav_src:gsub(
            'local project_root = vim%.fn%.getcwd%(%)',
            function()
              return "local _g = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\\n', '')\n    local project_root = (_g ~= '' and not _g:find('fatal')) and _g or vim.fn.getcwd()"
            end
          )
          local fnav_w = io.open(nav_path, 'w')
          if fnav_w then fnav_w:write(nav_src) fnav_w:close() end
        end
        vim.fn.system({'git', '-C', plugin_dir, 'update-index', '--assume-unchanged', 'lua/bookmarks/navigation.lua'})
      end

      -- telescope extension パッチ: 一覧表示の project_root を git root に統一
      local ext_path = plugin_dir .. '/lua/telescope/_extensions/bookmarks.lua'
      local fext = io.open(ext_path, 'r')
      if fext then
        local ext_src = fext:read('*a')
        fext:close()
        local changed = false
        if not ext_src:find('git rev%-parse.*show%-toplevel.*getcwd') then
          ext_src = ext_src:gsub(
            'storage%.get_bookmarks%(vim%.fn%.getcwd%(%),',
            function()
              return "storage.get_bookmarks((function() local g = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\\n','') return (g ~= '' and not g:find('fatal')) and g or vim.fn.getcwd() end)(),"
            end
          )
          changed = true
        end
        -- format_bookmark パッチ: ファイルパスを git root 基準の相対パスで表示
        if not ext_src:find('local _gr = vim%.fn%.system') then
          ext_src = ext_src:gsub(
            'local rel_path = vim%.fn%.fnamemodify%(bookmark%.filename, ":%."%)' ,
            function()
              return "local _gr = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\\n','')\n    local _fn = bookmark.filename:gsub('\\\\', '/')\n    local _grn = _gr:gsub('\\\\', '/')\n    local rel_path = (_grn ~= '' and not _grn:find('fatal') and _fn:find(_grn, 1, true) == 1)\n        and _fn:sub(#_grn + 2)\n        or vim.fn.fnamemodify(bookmark.filename, ':.')"
            end
          )
          changed = true
        end
        if changed then
          local fext_w = io.open(ext_path, 'w')
          if fext_w then fext_w:write(ext_src) fext_w:close() end
        end
        vim.fn.system({'git', '-C', plugin_dir, 'update-index', '--assume-unchanged', 'lua/telescope/_extensions/bookmarks.lua'})
      end
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
        title = title .. '  <C-l>=レイアウト切替 <C-d>=削除'

        require('telescope').extensions.bookmarks.list({
          prompt_title    = title,
          layout_strategy = telescope_layout_presets[1].layout_strategy,
          layout_config   = telescope_layout_presets[1].layout_config,
          attach_mappings = function(prompt_bufnr, map)
            local function delete_bookmark()
              local as = require('telescope.actions.state')
              local current_picker = as.get_current_picker(prompt_bufnr)
              local selection = as.get_selected_entry()
              if not (selection and selection.value) then return end
              local bmk = selection.value
              local cfg = require('bookmarks').get_config()
              local branch = cfg.use_branch_specific and require('bookmarks.utils').get_current_branch() or nil
              require('bookmarks.storage').remove_bookmark(bmk.filename, bmk.line, bmk.project_root, branch, bmk.list)
              local bufnr = vim.fn.bufnr(bmk.filename)
              if bufnr ~= -1 then require('bookmarks.autocmds').refresh_buffer(bufnr) end
              current_picker:delete_selection(function()
                vim.notify('Bookmark deleted', vim.log.levels.INFO)
              end)
            end
            map('i', '<C-d>', delete_bookmark)
            map('n', '<C-d>', delete_bookmark)

            local toggle_layout = make_layout_toggle(prompt_bufnr)
            map('i', '<C-l>', toggle_layout)
            map('n', '<C-l>', toggle_layout)
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
  -- Snippet
  { 'rainbow23/vim-snippets', lazy = false },
  -- LSP / Completion
  { 'williamboman/mason.nvim',           lazy = false },
  { 'williamboman/mason-lspconfig.nvim', lazy = false, dependencies = { 'williamboman/mason.nvim' } },
  { 'neovim/nvim-lspconfig',             lazy = false },
  { 'hrsh7th/nvim-cmp',                  lazy = false },
  { 'hrsh7th/cmp-nvim-lsp',             lazy = false },
  { 'hrsh7th/cmp-buffer',               lazy = false },
  { 'hrsh7th/cmp-path',                 lazy = false },
  { 'L3MON4D3/LuaSnip',                 lazy = false, build = 'make install_jsregexp' },
  { 'saadparwaiz1/cmp_luasnip',         lazy = false },
  { 'mfussenegger/nvim-jdtls',          lazy = false },
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
  -- ZoomWin は float window 実装に置き換えたため削除済み
  { 'vimlab/split-term.vim',      lazy = false },
  { 'osyo-manga/unite-quickfix',  lazy = false },
  { 'ujihisa/unite-colorscheme',  lazy = false },
  -- Denops plugins
  { 'Shougo/deol.nvim',                    lazy = false },
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
local previewers     = require('telescope.previewers')

-- i/n 両モードに同じキーマップを登録するユーティリティ
local function map_modes(map, key, fn)
  map('i', key, fn)
  map('n', key, fn)
end

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
    local toggle_layout = make_layout_toggle(prompt_bufnr)
    map_modes(map, '<C-h>', function(b) open_in_split(b, 'split') end)
    map_modes(map, '<C-f>', layout_actions.toggle_preview)
    map_modes(map, '<C-l>', toggle_layout)
    if extra_mappings then extra_mappings(prompt_bufnr, map) end
    return true
  end
end

local file_search_shortcut = '<C-r>=MRU <C-b>=Buffers <C-f>=Preview <C-l>=レイアウト切替 <C-t>=新規タブ <C-v>=vsplit <C-h>=hsplit'
local grep_search_shortcut = '<C-s>=Dir切替 <C-f>=Preview <C-l>=レイアウト切替 <C-t>=新規タブ <C-v>=vsplit <C-h>=hsplit'

local make_file_search   -- forward declaration
local make_grep_search   -- forward declaration

-- ロード済みのバッファファイル一覧を返すユーティリティ
local function get_buf_files()
  local files = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= '' and vim.fn.filereadable(name) == 1 then
        table.insert(files, name)
      end
    end
  end
  return files
end

local open_oldfiles_with_back = function(file_opts)
  builtin.oldfiles({
    prompt_title = 'Old Files  <C-r>=FileSearchに戻る',
    attach_mappings = function(prompt_bufnr, map)
      map_modes(map, '<C-r>', function(b)
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
      map_modes(map, '<C-b>', function(b)
        actions.close(b)
        vim.schedule(function() make_file_search(file_opts) end)
      end)
      return true
    end,
  })
end

make_file_search = function(opts)
  pickers.new(opts, {
    layout_strategy = telescope_layout_presets[1].layout_strategy,
    layout_config   = telescope_layout_presets[1].layout_config,
    prompt_title = (opts.base_title or 'FileSearch') .. ' [File] ' .. file_search_shortcut,
    finder = finders.new_oneshot_job(opts.files_cmd, {
      entry_maker = make_entry.gen_from_file(opts),
      cwd         = opts.cwd,
    }),
    previewer = conf.file_previewer(opts),
    sorter    = conf.file_sorter(opts),
    attach_mappings = make_attach_mappings(false, function(bufnr, map)
      map_modes(map, '<C-r>', function(b)
        actions.close(b)
        vim.schedule(function() open_oldfiles_with_back(opts) end)
      end)
      map_modes(map, '<C-b>', function(b)
        actions.close(b)
        vim.schedule(function() open_buffers_with_back(opts) end)
      end)
    end),
  }):find()
end

make_grep_search = function(opts)
  local grep_args  = vim.tbl_flatten({ conf.vimgrep_arguments, opts.additional_args or {} })
  local grep_entry = make_entry.gen_from_vimgrep(opts)

  -- ファイル名の初回到着順を記録し、ファイル順→行番号順でスコアを合成する
  -- rg --sort path によりファイルはアルファベット昇順で到着する
  local file_order   = {}
  local file_counter = 0
  local grep_line_sorter = require('telescope.sorters').Sorter:new({
    discard = false,
    scoring_function = function(_, _, _, entry)
      local fn = entry.filename or ''
      if not file_order[fn] then
        file_counter = file_counter + 1
        file_order[fn] = file_counter
      end
      -- 高スコア = 視覚的上位。ファイル順位が小さい・行番号が小さいほど高スコア
      -- 1000    : ファイル数の上限想定値。file_order は 1 始まりの連番なので
      --           (1000 - order) で「順位が小さいほど大きい値」に変換する。
      --           ファイルが 1000 個を超えると負値になり順序が崩れるため注意。
      -- 100000  : ファイル間優先度の重み（乗数）。行番号の最大想定値でもある。
      --           ファイル順位の差（最小 1）× 100000 が、行番号スコアの最大値
      --           (100000) を常に上回るため、ファイル順が行番号より必ず優先される。
      -- 100000 - lnum : 行番号が小さいほど大きい値になり、同一ファイル内で
      --           上の行が先に表示される。行番号が 100000 を超えるファイルでは
      --           負値になるが実用上は問題ない。
      return (1000 - file_order[fn]) * 100000 + (100000 - (entry.lnum or 0))
    end,
  })

  local cwd      = opts.cwd or vim.fn.getcwd()
  local git_root = opts.git_root
  local display_cwd
  if opts.buf_files then
    -- バッファ検索モード: ファイル数を表示
    display_cwd = string.format('buffers (%d files)', #opts.buf_files)
  elseif git_root then
    -- fnamemodify(':p') + スラッシュ統一で GitBash の /c/Users/... vs C:/Users/... 差異を吸収
    local cwd_n  = vim.fn.fnamemodify(cwd,      ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
    local root_n = vim.fn.fnamemodify(git_root, ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
    if cwd_n:find(root_n, 1, true) == 1 then
      local rel       = cwd_n:sub(#root_n + 1)  -- '' なら git root と一致
      local root_name = vim.fn.fnamemodify(root_n, ':t')
      display_cwd = root_name .. (rel == '' and '' or rel)  -- 例: "dotfiles" / "dotfiles/src/foo"
    else
      display_cwd = vim.fn.fnamemodify(cwd, ':~')  -- マッチしない場合は ~ 基準にフォールバック
    end
  else
    display_cwd = vim.fn.fnamemodify(cwd, ':~')  -- git 管理外は ~ 基準にフォールバック
  end
  pickers.new(opts, {
    layout_strategy = telescope_layout_presets[1].layout_strategy,
    layout_config   = telescope_layout_presets[1].layout_config,
    prompt_title = (opts.base_title or 'Search') .. ' [Grep]  Dir:' .. display_cwd .. '  ' .. grep_search_shortcut,
    finder = finders.new_job(function(prompt)
      if not prompt or prompt == '' then return nil end
      local cmd = vim.deepcopy(grep_args)
      table.insert(cmd, '--')
      table.insert(cmd, prompt)
      -- buf_files が指定されている場合はそのファイルのみを対象とする
      if opts.buf_files then
        for _, f in ipairs(opts.buf_files) do
          table.insert(cmd, f)
        end
      end
      return cmd
    end, grep_entry, nil, opts.cwd),
    previewer = conf.grep_previewer(opts),
    sorter    = grep_line_sorter,
    attach_mappings = make_attach_mappings(true, function(prompt_bufnr, map)
      -- <CR>: 既存ウィンドウに同ファイルが開いていればそこへ移動、なければ現在ウィンドウで開く
      local function select_entry(b)
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local filename = sel.filename or sel.path or ''
        local lnum = sel.lnum or 1
        local col  = (sel.col  or 1) - 1  -- Telescope は 1-based、nvim_win_set_cursor は 0-based
        if col < 0 then col = 0 end
        actions.close(b)
        vim.schedule(function()
          if filename == '' then return end
          local abs = vim.fn.fnamemodify(filename, ':p')
          local target_win = nil
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf  = vim.api.nvim_win_get_buf(win)
            local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':p')
            if name == abs then
              target_win = win
              break
            end
          end
          if target_win then
            vim.api.nvim_set_current_win(target_win)
          else
            vim.cmd('edit ' .. vim.fn.fnameescape(filename))
          end
          vim.api.nvim_win_set_cursor(0, { lnum, col })
          vim.cmd('normal! zz')
        end)
      end
      map_modes(map, '<CR>', select_entry)
      -- <C-s>: git root ↔ file dir 切替（file_dir か git_root が設定されているときのみ有効）
      if opts.file_dir or opts.git_root then
        local function toggle_dir(b)
          local query = action_state.get_current_picker(b):_get_prompt()
          actions.close(b)
          vim.schedule(function()
            local next_cwd   = (opts.cwd == opts.file_dir) and opts.git_root or opts.file_dir
            local next_title = (next_cwd == opts.file_dir) and 'GrepSearch (file dir)' or 'GrepSearch (git root)'
            make_grep_search({
              cwd             = next_cwd,
              default_text    = query,
              additional_args = opts.additional_args,
              base_title      = next_title,
              file_dir        = opts.file_dir,
              git_root        = opts.git_root,
            })
          end)
        end
        map_modes(map, '<C-s>', toggle_dir)
      end

    end),
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
  local file_dir = vim.fn.expand('%:p:h')
  make_grep_search({
    cwd             = git_root,
    default_text    = opts.args,
    additional_args = { '--hidden', '--smart-case', '--sort', 'path', '-g', '!.git/', '-g', '!.claude/' },
    base_title      = 'GrepSearch (git root)',
    file_dir        = file_dir,
    git_root        = git_root,
  })
end, { nargs = '*', bang = true })

vim.api.nvim_create_user_command('BufGrepSearch', function(opts)
  local buf_files = get_buf_files()
  if #buf_files == 0 then
    vim.notify('No buffer files to search', vim.log.levels.INFO)
    return
  end
  local git_root = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
  make_grep_search({
    cwd             = git_root ~= '' and not git_root:find('fatal') and git_root or vim.fn.getcwd(),
    default_text    = opts.args,
    additional_args = { '--hidden', '--smart-case', '--sort', 'path' },
    base_title      = 'BufGrepSearch',
    buf_files       = buf_files,
  })
end, { nargs = '*', bang = true })

vim.api.nvim_create_user_command('BLines', function(opts)
  local bufnr    = vim.api.nvim_get_current_buf()
  local lines    = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local filename = vim.api.nvim_buf_get_name(bufnr)

  local entries = {}
  for i, line in ipairs(lines) do
    table.insert(entries, { lnum = i, text = line, filename = filename })
  end

  local total = #lines
  local fzy = require('telescope.algos.fzy')
  local line_sorter = require('telescope.sorters').Sorter:new({
    scoring_function = function(_, prompt, line, entry)
      if prompt == '' then return total - entry.lnum + 1 end
      if not fzy.has_match(prompt:lower(), line:lower()) then return -1 end
      return total - entry.lnum + 1
    end,
  })

  pickers.new({}, {
    prompt_title = 'BLines',
    default_text = opts.args,
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value    = entry,
          display  = string.format('%4d│ %s', entry.lnum, entry.text),
          ordinal  = entry.text,
          filename = entry.filename,
          lnum     = entry.lnum,
          col      = 1,
        }
      end,
    }),
    layout_strategy = telescope_layout_presets[1].layout_strategy,
    layout_config   = telescope_layout_presets[1].layout_config,
    previewer       = conf.grep_previewer({}),
    sorter          = line_sorter,
    attach_mappings = make_attach_mappings(true),
  }):find()
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

-- セッション管理（telescope ベース）
local session_dir = vim.fn.expand('~/.vim/sessions')
vim.fn.mkdir(session_dir, 'p')

local function session_save(name)
  name = name or 'default'
  local path = session_dir .. '/' .. name .. '.vim'
  vim.cmd('mksession! ' .. vim.fn.fnameescape(path))
  vim.notify('Session saved: ' .. name, vim.log.levels.INFO)
end

local function session_load(name)
  local path = session_dir .. '/' .. name .. '.vim'
  vim.cmd('source ' .. vim.fn.fnameescape(path))
  vim.notify('Session loaded: ' .. name, vim.log.levels.INFO)
end

local function telescope_session_picker()
  -- 現在の git root を取得してセッションをフィルタリング
  -- git rev-parse の出力形式のまま保持し、セッション側も同じコマンドで取得して比較する
  -- （GitBash では expand('~') が C:/... を返し git が /c/... を返すため fnamemodify での
  --   正規化では吸収できない。同一コマンド出力同士を比較することで形式差異を回避する）
  local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
  local has_git  = git_root ~= '' and not git_root:find('fatal')

  local files = vim.fn.glob(session_dir .. '/*.vim', false, true)
  local names = {}
  for _, f in ipairs(files) do
    local include = true
    if has_git then
      -- セッションの cd 行からディレクトリを取得し、git -C でその git root を求めて照合
      include = false
      local fh = io.open(f, 'r')
      if fh then
        for line in fh:lines() do
          local dir = line:match('^cd%s+(.+)$')
          if dir then
            local expanded = vim.fn.expand(dir)
            local session_root = vim.fn.system(
              'git -C ' .. vim.fn.shellescape(expanded) .. ' rev-parse --show-toplevel 2>/dev/null'
            ):gsub('\n', '')
            if session_root == git_root then include = true end
            break
          end
        end
        fh:close()
      end
    end
    if include then
      table.insert(names, vim.fn.fnamemodify(f, ':t:r'))
    end
  end

  pickers.new({}, {
    prompt_title = '📂 Sessions  <CR>=ロード <C-d>=削除 <C-r>=リネーム <C-o>=上書保存',
    finder = finders.new_table({ results = names }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then session_load(sel[1]) end
      end)
      local function delete_session()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel then
          vim.fn.delete(session_dir .. '/' .. sel[1] .. '.vim')
          picker:delete_selection(function() vim.notify('Session deleted: ' .. sel[1]) end)
        end
      end
      local function rename_session()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local old_name = sel[1]
        actions.close(prompt_bufnr)
        vim.schedule(function()
          local new_name = vim.fn.input('Rename session: ', old_name)
          vim.cmd('redraw')
          if new_name == '' or new_name == old_name then return end
          local old_path = session_dir .. '/' .. old_name .. '.vim'
          local new_path = session_dir .. '/' .. new_name .. '.vim'
          if vim.fn.rename(old_path, new_path) == 0 then
            vim.notify('Session renamed: ' .. old_name .. ' → ' .. new_name, vim.log.levels.INFO)
          else
            vim.notify('Rename failed', vim.log.levels.ERROR)
          end
          telescope_session_picker()
        end)
      end
      local function overwrite_session()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        actions.close(prompt_bufnr)
        vim.schedule(function() session_save(sel[1]) end)
      end
      map_modes(map, '<C-d>', delete_session)
      map_modes(map, '<C-r>', rename_session)
      map_modes(map, '<C-o>', overwrite_session)
      return true
    end,
    layout_strategy = 'vertical',
    layout_config   = { height = 0.5, width = 0.4, prompt_position = 'top' },
  }):find()
end

vim.api.nvim_create_user_command('Uss', function(opts)
  session_save(opts.args ~= '' and opts.args or nil)
end, { nargs = '?' })

vim.keymap.set('n', 'uss',  '<Cmd>Uss<CR>', { desc = 'Session save (default)' })
vim.keymap.set('n', 'us',   telescope_session_picker, { desc = 'Session load (telescope)' })
vim.keymap.set('n', 'usos', function()
  local current = vim.v.this_session
  local name = (current ~= '') and vim.fn.fnamemodify(current, ':t:r') or 'default'
  local input = vim.fn.input('save current session? session_name=' .. name .. ' y or n ')
  vim.cmd('redraw')
  if input == 'y' then
    session_save(name)
  else
    vim.notify('canceled. session_name=' .. name, vim.log.levels.INFO)
  end
end, { desc = 'Session override save' })

-- メモ管理（extmarks ベース）
-- ファイルを変更せず仮想行としてメモを表示し、~/.vim/memos.json に永続化する
-- キーマップ: <leader>ma=追加/編集  <leader>md=削除  <leader>ml=一覧(telescope)
local memo_ns          = vim.api.nvim_create_namespace('user_memos')
local memo_file        = vim.fn.expand('~/.vim/memos.json')
local buf_memos        = {}  -- { [bufnr] = { [extmark_id] = text } }
local memo_loaded_bufs = {}  -- ロード済みバッファの管理

-- パス区切り文字を / に統一する（Windows/GitBash で \ と / が混在する問題を解消）
local function memo_normalize_path(path)
  return path:gsub('\\', '/')
end

local function memo_read_json()
  local f = io.open(memo_file, 'r')
  if not f then return {} end
  local s = f:read('*a'); f:close()
  local ok, t = pcall(vim.fn.json_decode, s)
  if not (ok and type(t) == 'table') then return {} end
  -- 既存 JSON のキーも / に正規化して返す（\ 混在の古いエントリとの互換性を保つ）
  local normalized = {}
  for k, v in pairs(t) do
    normalized[memo_normalize_path(k)] = v
  end
  return normalized
end

local function memo_write_json(data)
  local f = io.open(memo_file, 'w')
  if not f then return end
  f:write(vim.fn.json_encode(data)); f:close()
end

-- extmark を配置してバッファ内メモテーブルに登録する
local function memo_set_extmark(bufnr, line0, text)
  local id = vim.api.nvim_buf_set_extmark(bufnr, memo_ns, line0, 0, {
    virt_lines       = { { { '  📝 ' .. text, 'MemoHighlight' } } },
    virt_lines_above = false,
  })
  if not buf_memos[bufnr] then buf_memos[bufnr] = {} end
  buf_memos[bufnr][id] = text
  return id
end

-- extmark の現在行を読み取って JSON に書き出す
-- （extmark はバッファ内の編集に追従して行番号が変わるため、保存時に現在位置を取得する）
local function memo_flush_buf(bufnr)
  local ids = buf_memos[bufnr]
  if not ids then return end
  local filepath = memo_normalize_path(vim.api.nvim_buf_get_name(bufnr))
  if filepath == '' then return end
  local data    = memo_read_json()
  local entries = {}
  for id, text in pairs(ids) do
    local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, memo_ns, id, {})
    if pos and pos[1] then
      table.insert(entries, { line = pos[1] + 1, text = text })  -- JSON は 1-indexed
    end
  end
  data[filepath] = #entries > 0 and entries or nil
  memo_write_json(data)
end

-- バッファ読み込み時に JSON からメモを復元して extmark を配置する
local function memo_load_buf(bufnr)
  if memo_loaded_bufs[bufnr] then return end
  local filepath = memo_normalize_path(vim.api.nvim_buf_get_name(bufnr))
  -- filepath が確定してからロード済みフラグを立てる
  -- BufRead 時点でバッファ名が空の場合、先にフラグを立てると BufEnter でも再試行されなくなる
  if filepath == '' then return end
  memo_loaded_bufs[bufnr] = true
  -- vim.defer_fn で 100ms 遅延してから extmark を配置する
  -- vim.schedule だけではセッション復元時などにバッファ準備が間に合わない場合がある
  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    local entries = memo_read_json()[filepath]
    if not entries then return end
    vim.api.nvim_buf_clear_namespace(bufnr, memo_ns, 0, -1)
    buf_memos[bufnr] = {}
    for _, e in ipairs(entries) do
      memo_set_extmark(bufnr, e.line - 1, e.text)  -- extmark は 0-indexed
    end
  end, 100)
end

-- 現在行のメモを追加または編集する
local function memo_add_or_edit()
  local bufnr = vim.api.nvim_get_current_buf()
  local line0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  -- 現在行に既存メモがあれば取得する
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, memo_ns, { line0, 0 }, { line0, -1 }, {})
  local existing_id, existing_text
  if #marks > 0 then
    existing_id   = marks[1][1]
    existing_text = (buf_memos[bufnr] or {})[existing_id] or ''
  end
  local input = vim.fn.input('Memo: ', existing_text or '')
  vim.cmd('redraw')
  if input == '' then return end
  if existing_id then
    vim.api.nvim_buf_del_extmark(bufnr, memo_ns, existing_id)
    if buf_memos[bufnr] then buf_memos[bufnr][existing_id] = nil end
  end
  memo_set_extmark(bufnr, line0, input)
  memo_flush_buf(bufnr)
end

-- 現在行のメモを削除する
local function memo_delete()
  local bufnr = vim.api.nvim_get_current_buf()
  local line0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, memo_ns, { line0, 0 }, { line0, -1 }, {})
  if #marks == 0 then vim.notify('No memo on this line', vim.log.levels.INFO); return end
  local id = marks[1][1]
  vim.api.nvim_buf_del_extmark(bufnr, memo_ns, id)
  if buf_memos[bufnr] then buf_memos[bufnr][id] = nil end
  memo_flush_buf(bufnr)
  vim.notify('Memo deleted', vim.log.levels.INFO)
end

-- メモ一覧用ソーター: ファイル順 → 行番号順を維持しつつ prompt でフィルタリングする
-- GrepSearch と同じスコアリング式（ファイル順位 × 100000 + 行番号逆順）を使用
local function make_memo_sorter(results)
  local file_order   = {}
  local file_counter = 0
  for _, r in ipairs(results) do
    if not file_order[r.filepath] then
      file_counter = file_counter + 1
      file_order[r.filepath] = file_counter
    end
  end
  local fzy = require('telescope.algos.fzy')
  return require('telescope.sorters').Sorter:new({
    discard = false,
    scoring_function = function(_, prompt, line, entry)
      local fn   = (entry.value or {}).filepath or ''
      local lnum = (entry.value or {}).line or 0
      local rank = file_order[fn] or 999
      if prompt ~= '' and not fzy.has_match(prompt:lower(), (line or ''):lower()) then
        return -1
      end
      return (1000 - rank) * 100000 + (100000 - lnum)
    end,
  })
end

-- メモ専用プレビューア: メモテキスト + ファイル周辺行を表示する
-- grep_previewer はファイル内容のみでメモテキストが見えないため独自実装
local memo_previewer = previewers.new_buffer_previewer({
  define_preview = function(self, entry)
    local filepath = entry.value.filepath
    local lnum     = entry.value.line
    local text     = entry.value.text
    -- ヘッダにメモテキストを表示
    local header = { '📝  ' .. text, string.rep('─', 60), '' }
    -- ファイルの前後行を読み込んで表示（メモ行に ▶ マーカーを付ける）
    local body = {}
    local f = io.open(filepath, 'r')
    if f then
      local all = {}
      for line in f:lines() do table.insert(all, line) end
      f:close()
      local s = math.max(1, lnum - 5)
      local e = math.min(#all, lnum + 15)
      for i = s, e do
        table.insert(body, string.format('%s%4d  %s', i == lnum and '▶ ' or '  ', i, all[i] or ''))
      end
    end
    local lines = {}
    for _, l in ipairs(header) do table.insert(lines, l) end
    for _, l in ipairs(body)   do table.insert(lines, l) end
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_add_highlight(self.state.bufnr, -1, 'MemoHighlight', 0, 0, -1)
  end,
})

-- メモエントリを開いてジャンプする共通処理
local function memo_open_entry(b, cmd)
  local sel = action_state.get_selected_entry()
  if not sel then return end
  actions.close(b)
  vim.schedule(function()
    vim.cmd(cmd .. ' ' .. vim.fn.fnameescape(sel.value.filepath))
    vim.api.nvim_win_set_cursor(0, { sel.value.line, 0 })
    vim.cmd('normal! zz')
  end)
end

-- JSON とバッファ extmark からメモを削除する共通処理
local function memo_delete_from_store(fp, ln)
  local store = memo_read_json()
  if store[fp] then
    local kept = {}
    for _, e in ipairs(store[fp]) do
      if e.line ~= ln then table.insert(kept, e) end
    end
    store[fp] = #kept > 0 and kept or nil
    memo_write_json(store)
  end
  local bn = vim.fn.bufnr(fp)
  if bn ~= -1 and buf_memos[bn] then
    local ms = vim.api.nvim_buf_get_extmarks(bn, memo_ns, { ln - 1, 0 }, { ln - 1, -1 }, {})
    for _, m in ipairs(ms) do
      vim.api.nvim_buf_del_extmark(bn, memo_ns, m[1])
      buf_memos[bn][m[1]] = nil
    end
  end
end

-- メモピッカー共通キーマップ（<CR> <C-d> <C-l> <C-t> <M-v> <C-h>）
-- extra: 追加マッピング関数 function(prompt_bufnr, map) ... end（省略可）
local function make_memo_attach_mappings(extra)
  return function(prompt_bufnr, map)
    actions.select_default:replace(function() memo_open_entry(prompt_bufnr, 'edit') end)
    local function delete_memo()
      local sel = action_state.get_selected_entry()
      if not sel then return end
      local picker = action_state.get_current_picker(prompt_bufnr)
      memo_delete_from_store(sel.value.filepath, sel.value.line)
      picker:delete_selection(function() vim.notify('Memo deleted') end)
    end
    local toggle_layout = make_layout_toggle(prompt_bufnr)
    map_modes(map, '<C-d>', delete_memo)
    map_modes(map, '<C-l>', toggle_layout)
    map_modes(map, '<C-t>', function(b) memo_open_entry(b, 'tabedit') end)
    map_modes(map, '<M-v>', function(b) memo_open_entry(b, 'vsplit') end)
    map_modes(map, '<C-h>', function(b) memo_open_entry(b, 'split') end)
    if extra then extra(prompt_bufnr, map) end
    return true
  end
end

-- Telescope でメモ一覧を表示する
local function memo_list()
  local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
  local has_git  = git_root ~= '' and not git_root:find('fatal')
  local gr_norm  = has_git
    and vim.fn.fnamemodify(git_root, ':p'):gsub('[/\\]$', ''):gsub('\\', '/') or nil

  -- パス表示を git root 起点に変換する（gr_norm が nil なら ~ 基準）
  local function memo_display_path(filepath)
    if gr_norm then
      local fp_n = vim.fn.fnamemodify(filepath, ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
      if fp_n:find(gr_norm, 1, true) == 1 then
        local rel       = fp_n:sub(#gr_norm + 1)
        local root_name = vim.fn.fnamemodify(gr_norm, ':t')
        return root_name .. (rel == '' and '' or rel)
      end
    end
    return vim.fn.fnamemodify(filepath, ':~:.')
  end

  local data    = memo_read_json()
  local results = {}
  for filepath, entries in pairs(data) do
    -- git root 管理下のファイルのみを対象とする（git 管理外なら全件表示）
    if gr_norm then
      local fp_norm = vim.fn.fnamemodify(filepath, ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
      if fp_norm:find(gr_norm, 1, true) ~= 1 then goto continue end
    end
    for _, e in ipairs(entries) do
      table.insert(results, {
        filepath = filepath,
        line     = e.line,
        text     = e.text,
        display  = memo_display_path(filepath) .. ':' .. e.line .. '  ' .. e.text,
      })
    end
    ::continue::
  end
  table.sort(results, function(a, b)
    if a.filepath ~= b.filepath then return a.filepath < b.filepath end
    return a.line < b.line
  end)

  pickers.new({}, {
    prompt_title = '📝 Memos  <CR>=ジャンプ <C-d>=削除 <C-r>=リネーム <C-l>=レイアウト切替 <C-t>=新規タブ <M-v>=vsplit <C-h>=hsplit',
    finder = finders.new_table({
      results = results,
      entry_maker = function(e)
        return { value = e, display = e.display, ordinal = e.display, filename = e.filepath, lnum = e.line }
      end,
    }),
    sorter    = make_memo_sorter(results),
    previewer = memo_previewer,
    attach_mappings = make_memo_attach_mappings(function(prompt_bufnr, map)
      local function rename_memo()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local fp, ln = sel.value.filepath, sel.value.line
        actions.close(prompt_bufnr)
        vim.schedule(function()
          local new_text = vim.fn.input('Memo: ', sel.value.text)
          vim.cmd('redraw')
          if new_text == '' or new_text == sel.value.text then return end
          local store = memo_read_json()
          if store[fp] then
            for _, e in ipairs(store[fp]) do
              if e.line == ln then e.text = new_text; break end
            end
            memo_write_json(store)
          end
          local bufnr = vim.fn.bufnr(fp)
          if bufnr ~= -1 and buf_memos[bufnr] then
            local ms = vim.api.nvim_buf_get_extmarks(bufnr, memo_ns, { ln - 1, 0 }, { ln - 1, -1 }, {})
            for _, m in ipairs(ms) do
              vim.api.nvim_buf_del_extmark(bufnr, memo_ns, m[1])
              buf_memos[bufnr][m[1]] = nil
              memo_set_extmark(bufnr, ln - 1, new_text)
            end
          end
          memo_list()
        end)
      end
      map_modes(map, '<C-r>', rename_memo)
    end),
    layout_strategy = telescope_layout_presets[1].layout_strategy,
    layout_config   = telescope_layout_presets[1].layout_config,
  }):find()
end

-- メモのハイライト定義（colorscheme 変更後も維持する）
local function restore_memo_hl()
  vim.api.nvim_set_hl(0, 'MemoHighlight', { fg = '#FFD700', italic = true })
end
restore_memo_hl()
vim.api.nvim_create_autocmd({ 'VimEnter', 'ColorScheme' }, { callback = restore_memo_hl })

-- バッファ読み込み時にメモを自動ロードする
-- BufEnter も対象にすることでセッション復元など BufRead が発火しないケースも補足する
-- memo_loaded_bufs のガードにより二重ロードは発生しない
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile', 'BufEnter' }, {
  callback = function(args) memo_load_buf(args.buf) end,
})
-- バッファ破棄時に extmark の現在行を JSON に保存してからメモテーブルを解放する
-- （行挿入・削除で extmark が移動した場合、ここで保存しないと再オープン時に位置がずれる）
vim.api.nvim_create_autocmd('BufUnload', {
  callback = function(args)
    memo_flush_buf(args.buf)
    buf_memos[args.buf]        = nil
    memo_loaded_bufs[args.buf] = nil
  end,
})

-- 現在のバッファのメモのみを BLines レイアウトで表示する
local function memo_list_current()
  local bufnr    = vim.api.nvim_get_current_buf()
  local filepath = memo_normalize_path(vim.api.nvim_buf_get_name(bufnr))
  if filepath == '' then vim.notify('No file', vim.log.levels.INFO); return end
  local entries = memo_read_json()[filepath] or {}
  local results = {}
  for _, e in ipairs(entries) do
    table.insert(results, { filepath = filepath, line = e.line, text = e.text,
      display = string.format('%4d  %s', e.line, e.text) })
  end
  if #results == 0 then vim.notify('No memos in this file', vim.log.levels.INFO); return end
  pickers.new({}, {
    prompt_title    = '📝 Memos (current file)  <CR>=ジャンプ <C-d>=削除 <C-l>=レイアウト切替 <C-t>=新規タブ <M-v>=vsplit <C-h>=hsplit',
    finder          = finders.new_table({
      results     = results,
      entry_maker = function(e)
        return { value = e, display = e.display, ordinal = e.display, filename = e.filepath, lnum = e.line }
      end,
    }),
    sorter          = make_memo_sorter(results),
    previewer       = memo_previewer,
    layout_strategy = telescope_layout_presets[1].layout_strategy,
    layout_config   = telescope_layout_presets[1].layout_config,
    attach_mappings = make_memo_attach_mappings(),
  }):find()
end

-- memo_loaded_bufs フラグをリセットして強制的に再読み込みする
-- 自動ロードでメモが表示されなかった場合に使用する
local function memo_force_reload()
  local bufnr = vim.api.nvim_get_current_buf()
  memo_loaded_bufs[bufnr] = nil
  buf_memos[bufnr] = nil
  vim.api.nvim_buf_clear_namespace(bufnr, memo_ns, 0, -1)
  memo_load_buf(bufnr)
end

-- 開いているバッファのメモのみをTelescope一覧表示する
-- 選択時は既存ウィンドウへジャンプ（なければ現在ウィンドウで開く）
local function memo_list_buffers()
  -- ロード済みバッファのファイルパスをセットとして収集
  local buf_set = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      local name = memo_normalize_path(vim.api.nvim_buf_get_name(bufnr))
      if name ~= '' then buf_set[name] = true end
    end
  end

  local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
  local has_git  = git_root ~= '' and not git_root:find('fatal')
  local gr_norm  = has_git
    and vim.fn.fnamemodify(git_root, ':p'):gsub('[/\\]$', ''):gsub('\\', '/') or nil

  local function display_path(filepath)
    if gr_norm then
      local fp_n = vim.fn.fnamemodify(filepath, ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
      if fp_n:find(gr_norm, 1, true) == 1 then
        local rel       = fp_n:sub(#gr_norm + 1)
        local root_name = vim.fn.fnamemodify(gr_norm, ':t')
        return root_name .. (rel == '' and '' or rel)
      end
    end
    return vim.fn.fnamemodify(filepath, ':~:.')
  end

  -- バッファに含まれるファイルのメモのみを抽出
  local data    = memo_read_json()
  local results = {}
  for filepath, entries in pairs(data) do
    if buf_set[filepath] then
      for _, e in ipairs(entries) do
        table.insert(results, {
          filepath = filepath,
          line     = e.line,
          text     = e.text,
          display  = display_path(filepath) .. ':' .. e.line .. '  ' .. e.text,
        })
      end
    end
  end
  table.sort(results, function(a, b)
    if a.filepath ~= b.filepath then return a.filepath < b.filepath end
    return a.line < b.line
  end)

  if #results == 0 then
    vim.notify('No memos in open buffers', vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = '📝 Buffer Memos  <CR>=ジャンプ <C-d>=削除 <C-l>=レイアウト切替 <C-t>=新規タブ <M-v>=vsplit <C-h>=hsplit',
    finder = finders.new_table({
      results = results,
      entry_maker = function(e)
        return { value = e, display = e.display, ordinal = e.display, filename = e.filepath, lnum = e.line }
      end,
    }),
    sorter    = make_memo_sorter(results),
    previewer = memo_previewer,
    attach_mappings = function(prompt_bufnr, map)
      -- <CR>: 既存ウィンドウへジャンプ（バッファファイルのため通常は存在する）
      local function jump_to_win()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local filepath = sel.value.filepath
        local lnum     = sel.value.line
        actions.close(prompt_bufnr)
        -- vim.schedule だと Telescope のウィンドウ復元が間に合わないため
        -- defer_fn で少し待ってから処理する
        vim.defer_fn(function()
          -- vim.fn.bufnr() はパターンマッチするため全バッファを直接走査して完全一致で探す
          local target_bufnr = -1
          for _, b in ipairs(vim.api.nvim_list_bufs()) do
            if memo_normalize_path(vim.api.nvim_buf_get_name(b)) == filepath then
              target_bufnr = b
              break
            end
          end
          -- win_findbuf でそのバッファを表示しているウィンドウ一覧を取得
          local wins = target_bufnr ~= -1 and vim.fn.win_findbuf(target_bufnr) or {}
          if #wins > 0 then
            vim.api.nvim_set_current_win(wins[1])
          else
            vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
          end
          vim.api.nvim_win_set_cursor(0, { lnum, 0 })
          vim.cmd('normal! zz')
        end, 50)
      end
      actions.select_default:replace(jump_to_win)
      -- 削除・レイアウト・分割オープン
      local function delete_memo()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local picker = action_state.get_current_picker(prompt_bufnr)
        memo_delete_from_store(sel.value.filepath, sel.value.line)
        picker:delete_selection(function() vim.notify('Memo deleted') end)
      end
      local toggle_layout = make_layout_toggle(prompt_bufnr)
      map_modes(map, '<C-d>', delete_memo)
      map_modes(map, '<C-l>', toggle_layout)
      map_modes(map, '<C-t>', function(b) memo_open_entry(b, 'tabedit') end)
      map_modes(map, '<M-v>', function(b) memo_open_entry(b, 'vsplit') end)
      map_modes(map, '<C-h>', function(b) memo_open_entry(b, 'split') end)
      return true
    end,
    layout_strategy = telescope_layout_presets[1].layout_strategy,
    layout_config   = telescope_layout_presets[1].layout_config,
  }):find()
end

vim.api.nvim_create_user_command('MyBuffersMemos', memo_list_buffers, {})

vim.keymap.set('n', '<leader>ma', memo_add_or_edit,    { desc = 'Memo add/edit' })
vim.keymap.set('n', '<leader>md', memo_delete,         { desc = 'Memo delete' })
vim.keymap.set('n', '<leader>ml', memo_list,           { desc = 'Memo list (telescope)' })
vim.keymap.set('n', '<leader>ll', memo_list_current,   { desc = 'Memo list current file' })
vim.keymap.set('n', '<leader>mr', memo_force_reload,   { desc = 'Memo force reload' })

-- 起動時に stale な ShaDa tmp ファイルを削除する
-- Windows/GitBash 環境でクラッシュや複数インスタンス起動後に tmp ファイルが残留し
-- "cannot write ShaDa file!" エラーが出る問題への対処
-- 5秒以上前の tmp のみ削除することで、別インスタンスが書き込み中の tmp を誤削除しない
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    local shada_dir = vim.fn.stdpath('data') .. '/shada'
    for _, f in ipairs(vim.fn.glob(shada_dir .. '/main.shada.tmp*', false, true)) do
      local stat = vim.loop.fs_stat(f)
      if stat and (os.time() - stat.mtime.sec) > 5 then
        vim.fn.delete(f)
      end
    end
  end,
})

-- ZoomWin 代替: backdrop + float window で tmux popup 風の疑似最大化を実現する
-- ,, でトグル開閉
local zoom_float_id    = nil
local zoom_backdrop_id = nil

local function fullscreen_float(bufnr)
  local width  = math.floor(vim.o.columns * 0.95)
  local height = math.floor((vim.o.lines - vim.o.cmdheight - 1) * 0.95)
  local row    = math.floor((vim.o.lines   - height) / 2)
  local col    = math.floor((vim.o.columns - width)  / 2)
  local win = vim.api.nvim_open_win(bufnr or 0, true, {
    relative  = 'editor',
    row       = row,
    col       = col,
    width     = width,
    height    = height,
    border    = 'rounded',
    zindex    = 50,
  })
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].foldcolumn = '0'
  vim.wo[win].spell      = false
  return win
end

local function create_backdrop()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative  = 'editor',
    row       = 0,
    col       = 0,
    width     = vim.o.columns,
    height    = vim.o.lines,
    style     = 'minimal',
    border    = 'none',
    focusable = false,
    zindex    = 49,  -- メイン float (50) より手前・通常ウィンドウより奥
  })
  vim.wo[win].winhl = 'Normal:ZoomBackdrop'
  return win, buf
end

local function zoom_toggle()
  if zoom_float_id and vim.api.nvim_win_is_valid(zoom_float_id) then
    vim.api.nvim_win_close(zoom_float_id, false)
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local backdrop_win, backdrop_buf = create_backdrop()
  zoom_backdrop_id = backdrop_win
  zoom_float_id    = fullscreen_float(bufnr)
  -- winbar にファイル名と変更状態を表示（airline は floating window に非対応）
  vim.wo[zoom_float_id].winbar = ' %f %m'
  vim.api.nvim_create_autocmd('WinClosed', {
    pattern  = tostring(zoom_float_id),
    once     = true,
    callback = function()
      zoom_float_id = nil
      -- backdrop を閉じてスクラッチバッファを削除する
      if zoom_backdrop_id and vim.api.nvim_win_is_valid(zoom_backdrop_id) then
        vim.api.nvim_win_close(zoom_backdrop_id, true)
      end
      zoom_backdrop_id = nil
      pcall(vim.api.nvim_buf_delete, backdrop_buf, { force = true })
    end,
  })
end

vim.keymap.set('n', ',,', zoom_toggle, { desc = 'Zoom window toggle (float)' })

-- UI ハイライト（colorscheme 適用後に再定義）
local function restore_ui_hl()
  vim.api.nvim_set_hl(0, 'TelescopeSelection', { bg = '#87CEEB', fg = '#000000', bold = true })
  vim.api.nvim_set_hl(0, 'TabLineSel',         { bg = '#87CEEB', fg = '#000000', bold = true })
  -- NormalFloat を Normal にリンク: iTerm 半透明環境で float が白くなるのを防ぐ
  vim.api.nvim_set_hl(0, 'NormalFloat',  { link = 'Normal' })
  -- float window の枠線を白色にする
  vim.api.nvim_set_hl(0, 'FloatBorder',  { fg = '#FFFFFF' })
  -- zoom backdrop: tmux popup 風の灰色背景
  vim.api.nvim_set_hl(0, 'ZoomBackdrop', { bg = '#3a3a3a', fg = '#3a3a3a' })
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

-- ⑥ LSP / 補完設定
require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = {
    'kotlin_language_server',
    'ts_ls',
    'sqlls',
    'lua_ls',
    'vimls',
    'bashls',
  },
})

-- LuaSnip（vim-snippets の snipmate 形式スニペットを読み込む）
local luasnip = require('luasnip')
require('luasnip.loaders.from_snipmate').lazy_load()

-- nvim-cmp
local cmp = require('cmp')
cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>']     = cmp.mapping.abort(),
    ['<CR>']      = cmp.mapping.confirm({ select = true }),
    ['<Tab>']     = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { 'i', 's' }),
    ['<S-Tab>']   = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources(
    { { name = 'nvim_lsp' }, { name = 'luasnip' } },
    { { name = 'buffer' },   { name = 'path' } }
  ),
})

-- LSP 共通設定
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local map = function(keys, func)
      vim.keymap.set('n', keys, func, { buffer = bufnr, silent = true })
    end
    map('gd',         vim.lsp.buf.definition)
    map('gr',         vim.lsp.buf.references)
    map('K',          vim.lsp.buf.hover)
    map('<leader>rn', vim.lsp.buf.rename)
    map('<leader>ca', vim.lsp.buf.code_action)
    map('[d',         vim.diagnostic.goto_prev)
    map(']d',         vim.diagnostic.goto_next)
  end,
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()
vim.lsp.config('*', { capabilities = capabilities })

-- lua_ls（Neovim API を認識させる追加設定）
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime    = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace  = { library = vim.api.nvim_get_runtime_file('', true), checkThirdParty = false },
      telemetry  = { enable = false },
    },
  },
})

vim.lsp.enable({ 'kotlin_language_server', 'ts_ls', 'sqlls', 'vimls', 'bashls', 'lua_ls' })

-- Java（nvim-jdtls）
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function()
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
    require('jdtls').start_or_attach({
      cmd = {
        vim.fn.stdpath('data') .. '/mason/bin/jdtls',
        '-data', vim.fn.stdpath('data') .. '/jdtls-workspace/' .. project_name,
      },
      root_dir = vim.fs.dirname(vim.fs.find(
        { 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', 'build.gradle.kts', '.git' },
        { upward = true }
      )[1]),
      capabilities = capabilities,
    })
  end,
})

-- Search / SearchFromCurrDir を telescope に置き換え
-- File モード: ファイル名を fuzzy 検索 / Grep モード: ファイル内文字列を live grep
-- <C-t> で両モード切り替え（クエリ文字列を引き継ぐ）
-- _vimrc の fzf 版は has('nvim') で無効化済み
local conf         = require('telescope.config').values
local finders      = require('telescope.finders')
local pickers      = require('telescope.pickers')
local make_entry   = require('telescope.make_entry')
local actions        = require('telescope.actions')
local action_state   = require('telescope.actions.state')
local layout_actions = require('telescope.actions.layout')
local builtin        = require('telescope.builtin')

local util                     = require('rc.util')
local map_modes                = util.map_modes
local make_layout_toggle       = util.make_layout_toggle
local telescope_layout_presets = util.telescope_layout_presets

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
          local function jump()
            local safe_lnum = math.max(1, math.min(lnum, vim.api.nvim_buf_line_count(0)))
            vim.api.nvim_win_set_cursor(0, { safe_lnum, col })
            vim.cmd('normal! zz')
          end
          if target_win then
            vim.api.nvim_set_current_win(target_win)
            jump()
          else
            vim.cmd('edit ' .. vim.fn.fnameescape(filename))
            -- Windows でバッファロード完了前にカーソル設定するとエラーになるため defer
            vim.defer_fn(jump, 50)
          end
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

-- [fzf]m（vimrc.d/search-keymaps.vim）用: fzf 版 MRU を telescope oldfiles で置き換え
-- plain vim では vimrc.d/fzf.vim が同名コマンドを定義する
vim.api.nvim_create_user_command('FZFMru', function(opts)
  builtin.oldfiles({ default_text = opts.args })
end, { nargs = '*', bang = true })

vim.api.nvim_create_user_command('FileSearchFromCurrDir', function(opts)
  make_file_search({
    cwd       = vim.fn.getcwd(),
    default_text = opts.args,
    files_cmd = { 'rg', '--files', '--hidden', '--color=never', '-g', '!.claude/' },
    base_title = 'FileSearch (cwd)',
  })
end, { nargs = '*', bang = true })

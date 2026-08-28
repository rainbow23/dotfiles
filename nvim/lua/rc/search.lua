-- Search / SearchFromCurrDir を telescope に置き換え
-- File モード: ファイル名を fuzzy 検索 / Grep モード: ファイル内文字列を live grep
-- <C-t> で両モード切り替え（クエリ文字列を引き継ぐ）
-- _vimrc の fzf 版は has('nvim') で無効化済み
local conf         = require('telescope.config').values
local finders      = require('telescope.finders')
local pickers      = require('telescope.pickers')
local make_entry   = require('telescope.make_entry')
local actions      = require('telescope.actions')
local action_state = require('telescope.actions.state')
local builtin      = require('telescope.builtin')

local util               = require('rc.util')
local map_modes          = util.map_modes
local make_attach_mappings = util.make_attach_mappings

local file_search_shortcut = '<C-r>=MRU <C-b>=Buffers ' .. util.shortcut_common
local grep_search_shortcut = '<C-s>=Dir切替 <C-o>=Sort ' .. util.shortcut_common

local make_file_search   -- forward declaration
local make_grep_search   -- forward declaration

-- <C-s> 階層ナビゲーション共通ロジック
-- git root → file dir → 親ディレクトリ → ... → git root で循環
local function next_cwd_for_dir_nav(cwd, git_root, file_dir)
  local cwd_n  = vim.fn.fnamemodify(cwd, ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
  local root_n = vim.fn.fnamemodify(git_root, ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
  if cwd_n == root_n and file_dir then
    return file_dir
  end
  local parent   = vim.fn.fnamemodify(cwd, ':h')
  local parent_n = vim.fn.fnamemodify(parent, ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
  if #parent_n < #root_n or parent == cwd then
    return git_root
  end
  return parent
end

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
    prompt_title    = 'Old Files  <C-r>=FileSearchに戻る ' .. util.shortcut_common,
    attach_mappings = make_attach_mappings(false, function(_, map)
      map_modes(map, '<C-r>', function(b)
        actions.close(b)
        vim.schedule(function() make_file_search(file_opts) end)
      end)
    end),
  })
end

local open_buffers_with_back = function(file_opts)
  builtin.buffers({
    prompt_title    = 'Buffers  <C-b>=FileSearchに戻る ' .. util.shortcut_common,
    attach_mappings = make_attach_mappings(false, function(_, map)
      map_modes(map, '<C-b>', function(b)
        actions.close(b)
        vim.schedule(function() make_file_search(file_opts) end)
      end)
    end),
  })
end

make_file_search = function(opts)
  -- Dir 表示を組み立てる（git_root がある場合のみ表示）
  local dir_label = ''
  local shortcut  = file_search_shortcut
  if opts.git_root then
    local cwd_n  = vim.fn.fnamemodify(opts.cwd, ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
    local root_n = vim.fn.fnamemodify(opts.git_root, ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
    if cwd_n:find(root_n, 1, true) == 1 then
      local rel       = cwd_n:sub(#root_n + 1)
      local root_name = vim.fn.fnamemodify(root_n, ':t')
      dir_label = root_name .. (rel == '' and '' or rel)
    else
      dir_label = vim.fn.fnamemodify(opts.cwd, ':~')
    end
    dir_label = '  Dir:' .. dir_label .. '  '
    shortcut  = '<C-s>=Dir切替 ' .. file_search_shortcut
  else
    dir_label = ' '
  end

  pickers.new(opts, {
    prompt_title = (opts.base_title or 'FileSearch') .. ' [File]' .. dir_label .. shortcut,
    finder = finders.new_oneshot_job(opts.files_cmd, {
      entry_maker = make_entry.gen_from_file(opts),
      cwd         = opts.cwd,
    }),
    previewer = conf.file_previewer(opts),
    sorter    = conf.file_sorter(opts),
    attach_mappings = make_attach_mappings(false, function(bufnr, map)
      -- <C-s>: git root → file dir → 上階層 → ... → git root で循環
      if opts.git_root then
        map_modes(map, '<C-s>', function(b)
          local query = action_state.get_current_picker(b):_get_prompt()
          local next  = next_cwd_for_dir_nav(opts.cwd, opts.git_root, opts.file_dir)
          actions.close(b)
          vim.schedule(function()
            make_file_search({
              cwd          = next,
              default_text = query,
              files_cmd    = opts.files_cmd,
              base_title   = opts.base_title,
              git_root     = opts.git_root,
              file_dir     = opts.file_dir,
            })
          end)
        end)
      end
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

  -- ファイル名文字列→行番号の順でスコアを合成するソーター
  -- --sort path を使わず rg がストリーミング出力するため、ファイル名で安定ソートする
  -- scoring_function の戻り値は「高いほど上位表示」
  local grep_line_sorter = require('telescope.sorters').Sorter:new({
    discard = false,
    scoring_function = function(_, _, _, entry)
      local fn   = entry.filename or ''
      -- ファイル名の先頭 6 文字を数値化してファイル間の大小比較に使う
      -- 同一ファイル内は行番号で細分（行番号が小さいほど高スコア）
      local file_score = 0
      for i = 1, math.min(6, #fn) do
        file_score = file_score * 256 + fn:byte(i)
      end
      -- file_score が大きい（辞書順で後ろ）ほどスコアを下げる
      return -file_score * 100000 + (100000 - (entry.lnum or 0))
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
      -- <C-o>: 現在の結果をファイル名→行番号で昇順ソートして静的リストに切替
      map_modes(map, '<C-o>', function(b)
        local picker  = action_state.get_current_picker(b)
        local entries = {}
        for entry in picker.manager:iter() do
          table.insert(entries, entry)
        end
        table.sort(entries, function(x, y)
          if (x.filename or '') ~= (y.filename or '') then
            return (x.filename or '') < (y.filename or '')
          end
          return (x.lnum or 0) < (y.lnum or 0)
        end)
        picker:refresh(finders.new_table({
          results     = entries,
          entry_maker = function(e) return e end,
        }), { reset_prompt = false })
        vim.api.nvim_echo({ { 'Sorted ' .. #entries .. ' entries', 'None' } }, false, {})
      end)
      -- <C-s>: git root → file dir → 上階層 → ... → git root で循環
      if opts.git_root then
        map_modes(map, '<C-s>', function(b)
          local query = action_state.get_current_picker(b):_get_prompt()
          local next  = next_cwd_for_dir_nav(opts.cwd, opts.git_root, opts.file_dir)
          actions.close(b)
          vim.schedule(function()
            make_grep_search({
              cwd             = next,
              default_text    = query,
              additional_args = opts.additional_args,
              base_title      = opts.base_title,
              file_dir        = opts.file_dir,
              git_root        = opts.git_root,
            })
          end)
        end)
      end

    end),
  }):find()
end


-- [fzf]b: Telescope buffers（fzf.vim の :Buffers を上書き）
vim.api.nvim_create_user_command('Buffers', function(opts)
  builtin.buffers({
    default_text    = opts.args,
    prompt_title    = 'Buffers  ' .. util.shortcut_common,
    attach_mappings = make_attach_mappings(false),
  })
end, { nargs = '*' })

-- [fzf]w: Telescope ウィンドウ一覧（fzf.vim の :Windows を上書き）
vim.api.nvim_create_user_command('Windows', function()
  local results = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf  = vim.api.nvim_win_get_buf(win)
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':~:.')
    if name == '' then name = '[No Name]' end
    local pos = vim.api.nvim_win_get_position(win)
    table.insert(results, {
      win     = win,
      name    = name,
      display = string.format('%-50s  row:%-4d col:%d', name, pos[1], pos[2]),
    })
  end
  pickers.new({}, {
    prompt_title = 'Windows  <CR>=ジャンプ',
    finder = finders.new_table({
      results     = results,
      entry_maker = function(e)
        return { value = e, display = e.display, ordinal = e.name }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local sel = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.schedule(function()
          if sel and vim.api.nvim_win_is_valid(sel.value.win) then
            vim.api.nvim_set_current_win(sel.value.win)
          end
        end)
      end)
      return true
    end,
    layout_strategy = 'center',
    layout_config   = { width = 0.7, height = 0.5 },
  }):find()
end, {})

vim.api.nvim_create_user_command('FileSearch', function(opts)
  local git_root = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
  local has_git  = git_root ~= '' and not git_root:find('fatal')
  local file_dir = vim.fn.expand('%:p:h')
  make_file_search({
    cwd          = has_git and git_root or vim.fn.getcwd(),
    default_text = opts.args,
    files_cmd    = { 'rg', '--files', '--hidden', '--color=never', '-g', '!.git/', '-g', '!.claude/' },
    base_title   = 'FileSearch',
    git_root     = has_git and git_root or nil,
    file_dir     = file_dir,
  })
end, { nargs = '*', bang = true })

vim.api.nvim_create_user_command('GrepSearch', function(opts)
  local git_root = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
  local file_dir = vim.fn.expand('%:p:h')
  make_grep_search({
    cwd             = git_root,
    default_text    = opts.args,
    additional_args = { '--hidden', '--smart-case', '-g', '!.git/', '-g', '!.claude/' },
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
    prompt_title = 'BLines  ' .. util.shortcut_common,
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
    previewer       = conf.grep_previewer({}),
    sorter          = line_sorter,
    attach_mappings = make_attach_mappings(true),
  }):find()
end, { nargs = '*', bang = true })

vim.api.nvim_create_user_command('GitStatus', function(opts)
  builtin.git_status({
    default_text    = opts.args,
    prompt_title    = 'GitStatus  ' .. util.shortcut_common,
    attach_mappings = make_attach_mappings(true),
  })
end, { nargs = '*', bang = true })

-- [fzf]m（vimrc.d/search-keymaps.vim）用: fzf 版 MRU を telescope oldfiles で置き換え
-- plain vim では vimrc.d/fzf.vim が同名コマンドを定義する
vim.api.nvim_create_user_command('FZFMru', function(opts)
  builtin.oldfiles({
    default_text    = opts.args,
    prompt_title    = 'MRU  ' .. util.shortcut_common,
    attach_mappings = make_attach_mappings(false),
  })
end, { nargs = '*', bang = true })


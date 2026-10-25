-- FileSearch / GrepSearch の検索履歴（プロジェクト = git root ごとに保存）
-- 保存先: ~/.vim/search_history/<root の / を % に置換>.json
-- 形式: { version = 1, root = '...', file = { {query, used_at, count}, ... }, grep = { ... } }
local conf         = require('telescope.config').values
local finders      = require('telescope.finders')
local pickers      = require('telescope.pickers')
local actions      = require('telescope.actions')
local action_state = require('telescope.actions.state')

local util      = require('rc.util')
local map_modes = util.map_modes

local M = {}

local history_dir = vim.fn.expand('~/.vim/search_history')
vim.fn.mkdir(history_dir, 'p')

local MAX_ENTRIES = 100
local MIN_LENGTH  = 2

-- 他モードの検索を開く関数（search.lua から登録）: { file = function(query) end, grep = function(query) end }
M.launchers = {}

local function normalize(path)
  return (vim.fn.fnamemodify(path, ':p'):gsub('\\', '/'):gsub('/$', ''))
end

-- 履歴のキーにするディレクトリを決める
-- git root が有効ならそれ、なければ cwd（git rev-parse 失敗時の "fatal: ..." 文字列は無効扱い）
function M.resolve_root(git_root, cwd)
  local function valid(p)
    return p and p ~= '' and not p:find('fatal') and vim.fn.isdirectory(p) == 1
  end
  if valid(git_root) then return normalize(git_root) end
  if valid(cwd) then return normalize(cwd) end
  return normalize(vim.fn.getcwd())
end

-- 現在のバッファ（なければ cwd）から履歴のキーを求める
function M.current_root()
  local git_root = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
  return M.resolve_root(git_root, vim.fn.getcwd())
end

local function history_path(root)
  return history_dir .. '/' .. root:gsub('[/\\:]', '%%') .. '.json'
end

local function read_data(root)
  local data
  local fh = io.open(history_path(root), 'r')
  if fh then
    local raw = fh:read('*a')
    fh:close()
    local ok, decoded = pcall(vim.fn.json_decode, raw)
    if ok and type(decoded) == 'table' then data = decoded end
  end
  -- 壊れたファイルは空履歴として扱い、次回保存時に上書きして自己修復する
  data = data or {}
  data.version = 1
  data.root    = root
  data.file    = type(data.file) == 'table' and data.file or {}
  data.grep    = type(data.grep) == 'table' and data.grep or {}
  return data
end

local function write_data(root, data)
  local fh = io.open(history_path(root), 'w')
  if fh then
    fh:write(vim.fn.json_encode(data))
    fh:close()
  end
end

-- mode: 'file' | 'grep' → そのプロジェクトの entries（新しい順）
function M.load(mode, root)
  return read_data(root)[mode]
end

-- 重複は先頭へ移動し、上限を超えた古い履歴は捨てる
function M.add(mode, query, root)
  if not query or #query < MIN_LENGTH then return end
  local data  = read_data(root)
  local count = 0
  local list  = {}
  for _, e in ipairs(data[mode]) do
    if e.query == query then
      count = e.count or 0
    else
      table.insert(list, e)
    end
  end
  table.insert(list, 1, { query = query, used_at = os.time(), count = count + 1 })
  while #list > MAX_ENTRIES do table.remove(list) end
  data[mode] = list
  write_data(root, data)
end

function M.remove(mode, queries, root)
  local drop = {}
  for _, q in ipairs(queries) do drop[q] = true end
  local data = read_data(root)
  local list = {}
  for _, e in ipairs(data[mode]) do
    if not drop[e.query] then table.insert(list, e) end
  end
  data[mode] = list
  write_data(root, data)
end

-- <C-k>/<C-j> 中に入力欄の真上へ出す履歴ポップアップ
local POPUP_MAX_HEIGHT = 10

local function popup_close(state)
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

-- 履歴を古い順に上から並べ（最新が入力欄に一番近い最下行）、idx 番目に新しい履歴の行をハイライトする
-- （ウィンドウがなければ作る）
local function popup_show(state, prompt_win, list, idx)
  if not vim.api.nvim_win_is_valid(prompt_win) then return end
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = 'wipe'
    local lines = {}
    for i = #list, 1, -1 do table.insert(lines, ' ' .. list[i].query) end
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    vim.bo[state.buf].modifiable = false
  end
  local title = string.format(' History (%d/%d)  <C-k>/<C-p>=上(古い) <C-j>/<C-n>=下(新しい) <CR>=確定 ', idx, #list)
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
    -- 入力欄の上端ボーダーのすぐ上に、ポップアップの下端ボーダーが来るように置く
    -- （row/col はボーダーを含む外枠の左上。ボーダー分の 2 行も差し引く）
    local pos    = vim.api.nvim_win_get_position(prompt_win)
    local height = math.min(#list, POPUP_MAX_HEIGHT)
    state.win = vim.api.nvim_open_win(state.buf, false, {
      relative  = 'editor',
      row       = math.max(0, pos[1] - 1 - (height + 2)),
      col       = math.max(0, pos[2] - 1),
      width     = vim.api.nvim_win_get_width(prompt_win),
      height    = height,
      style     = 'minimal',
      border    = 'rounded',
      title     = title,
      focusable = false,
      zindex    = 200,
    })
    vim.wo[state.win].cursorline   = true
    vim.wo[state.win].winhighlight = 'Normal:PopupText,FloatBorder:TelescopePromptBorder,FloatTitle:PopupTitle,CursorLine:TelescopeSelection'
  else
    vim.api.nvim_win_set_config(state.win, { title = title })
  end
  vim.api.nvim_win_set_cursor(state.win, { #list - idx + 1, 0 })
end

-- 検索 picker の attach_mappings 内で呼ぶ
-- 閉じるたびにプロンプトを記録し、<C-k>/<C-j> で履歴を呼び出し、<C-e> で履歴一覧を開く
-- args: { mode, root, reopen = function(query) 同じ条件で開き直す end, is_static = function() 静的リスト化済みか end,
--         popup = true で <C-k>/<C-j> 中に入力欄の上へ履歴ポップアップを表示 }
function M.attach(prompt_bufnr, map, args)
  local popup = {}
  -- picker を閉じたら記録する。telescope 標準の <CR>/<C-t> などは actions.close を通らず
  -- on_close_prompt を直接呼ぶため、telescope 自身と同じく prompt バッファの BufLeave で閉じたとみなす
  local picker = action_state.get_current_picker(prompt_bufnr)
  vim.api.nvim_create_autocmd('BufLeave', {
    buffer   = prompt_bufnr,
    once     = true,
    callback = function()
      local ok, query = pcall(function() return picker:_get_prompt() end)
      if ok then M.add(args.mode, query, args.root) end
      popup_close(popup)
    end,
  })

  local list = M.load(args.mode, args.root)
  local idx = 0    -- 0 = 履歴未選択、1 = 最新、#list = 最古
  local last_set   -- 履歴で入力欄に入れた文字列（手入力との区別用）

  local function show(b)
    local picker = action_state.get_current_picker(b)
    last_set = list[idx].query
    picker:set_prompt(last_set)
    if args.popup then popup_show(popup, picker.prompt_win, list, idx) end
  end

  if args.popup then
    -- 手入力で入力欄が変わったらポップアップを閉じる（set_prompt による変更は last_set と一致するので無視）
    vim.api.nvim_buf_attach(prompt_bufnr, false, {
      on_lines = function()
        vim.schedule(function()
          if not popup.win or not vim.api.nvim_buf_is_valid(prompt_bufnr) then return end
          local picker = action_state.get_current_picker(prompt_bufnr)
          if picker and picker:_get_prompt() ~= last_set then popup_close(popup) end
        end)
      end,
    })
  end

  local function guard_static()
    if args.is_static and args.is_static() then
      vim.notify('Pinned/Sorted 中は履歴を使えません', vim.log.levels.INFO)
      return true
    end
    return false
  end

  local function up(b)
    if guard_static() then return end
    if #list == 0 then
      vim.notify('No search history', vim.log.levels.INFO)
      return
    end
    -- 初回は最新（ポップアップ最下行）を選択し、以降は 1 つ上（古い方）へ
    idx = math.min(idx + 1, #list)
    show(b)
  end
  -- 1 つ下（新しい方）へ。最新（最下行）で止まる
  local function down(b)
    if guard_static() or idx <= 1 then return end
    idx = idx - 1
    show(b)
  end
  map_modes(map, '<C-k>', up)
  map_modes(map, '<C-j>', down)
  -- <C-p>/<C-n>: ポップアップ表示中だけ上/下。表示中でなければ telescope 標準の候補移動
  local function popup_open() return popup.win and vim.api.nvim_win_is_valid(popup.win) end
  map_modes(map, '<C-p>', function(b)
    if popup_open() then up(b) else actions.move_selection_previous(b) end
  end)
  map_modes(map, '<C-n>', function(b)
    if popup_open() then down(b) else actions.move_selection_next(b) end
  end)
  map_modes(map, '<C-e>', function(b)
    actions.close(b)
    vim.schedule(function()
      M.open_picker(args.mode, args.root, { mode = args.mode, reopen = args.reopen })
    end)
  end)

  -- ポップアップ表示中の <CR>: ポップアップだけ閉じ、選択中の文言を入力欄に残して編集できる状態にする
  -- 表示中でなければ false を返し、呼び出し側の通常の <CR>（ファイルを開く）に任せる
  local function confirm(b)
    if not (popup.win and vim.api.nvim_win_is_valid(popup.win)) then return false end
    popup_close(popup)
    -- 次の <C-k> は再び最新の履歴から始める
    idx = 0
    local picker = action_state.get_current_picker(b)
    if vim.api.nvim_get_mode().mode ~= 'i' then
      vim.cmd('startinsert!')
    elseif picker and vim.api.nvim_win_is_valid(picker.prompt_win) then
      local line = vim.api.nvim_buf_get_lines(b, 0, 1, false)[1] or ''
      vim.api.nvim_win_set_cursor(picker.prompt_win, { 1, #line })
    end
    return true
  end

  -- close_popup: 呼び出し側で静的リスト化（Pinned/Sort）したときにポップアップを閉じる
  -- confirm: <CR> の先頭で呼ぶ（true ならポップアップを確定して閉じたので通常処理をしない）
  return { close_popup = function() popup_close(popup) end, confirm = confirm }
end

-- 履歴一覧 picker
-- back: { mode, reopen } 呼び出し元の検索。同じモードの履歴を選んだ場合は元の条件（cwd など）で開き直す
function M.open_picker(mode, root, back)
  local list  = M.load(mode, root)
  local label = mode == 'file' and 'File' or 'Grep'
  pickers.new({}, {
    prompt_title  = string.format('SearchHistory [%s]  Project:%s  <CR>=再検索 <C-d>=削除 <C-e>=File/Grep切替',
      label, vim.fn.fnamemodify(root, ':t')),
    finder = finders.new_table({
      results     = list,
      entry_maker = function(e)
        return {
          value   = e,
          display = os.date('%Y-%m-%d %H:%M', e.used_at or 0) .. '  ' .. e.query,
          ordinal = e.query,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, _map)
      actions.select_default:replace(function(b)
        local sel = action_state.get_selected_entry()
        actions.close(b)
        if not sel then return end
        local query = sel.value.query
        vim.schedule(function()
          if back and back.mode == mode and back.reopen then
            back.reopen(query)
          elseif M.launchers[mode] then
            M.launchers[mode](query)
          end
        end)
      end)
      map_modes(_map, '<Tab>', function(b)
        actions.toggle_selection(b)
        actions.move_selection_worse(b)
      end)
      map_modes(_map, '<S-Tab>', function(b)
        actions.toggle_selection(b)
        actions.move_selection_better(b)
      end)
      -- <C-d>: カーソル行（複数選択時は選択行すべて）を履歴から削除
      map_modes(_map, '<C-d>', function(b)
        local picker   = action_state.get_current_picker(b)
        local selected = picker:get_multi_selection()
        if #selected == 0 then
          local sel = action_state.get_selected_entry()
          if sel then selected = { sel } end
        end
        if #selected == 0 then return end
        local queries = {}
        for _, s in ipairs(selected) do table.insert(queries, s.value.query) end
        M.remove(mode, queries, root)
        actions.close(b)
        vim.schedule(function() M.open_picker(mode, root, back) end)
        vim.notify('Deleted ' .. #queries .. ' history entries')
      end)
      map_modes(_map, '<C-e>', function(b)
        actions.close(b)
        vim.schedule(function() M.open_picker(mode == 'file' and 'grep' or 'file', root, back) end)
      end)
      return true
    end,
    layout_strategy = 'center',
    layout_config   = { width = 0.7, height = 0.5 },
  }):find()
end

return M

-- メモ管理（extmarks ベース）
-- ファイルを変更せず仮想行としてメモを表示し、~/.vim/memos.json に永続化する
-- キーマップ: <leader>ma=追加/編集 <leader>ms=リストから追加 <leader>me=候補編集 <leader>md=削除 <leader>ml=一覧
--            <leader>mm=最近使ったメモ一覧（MRU）
--            一覧表示中は <M-1>=Recent <M-2>=Current <M-3>=Buffers <M-4>=All <M-5>=Active で切り替え
--            <leader>mv=アクティブメモ一覧 <leader>mg=フィルター決定 <leader>mt=フィルタートグル <leader>mo=フィルター一覧
local finders        = require('telescope.finders')
local pickers        = require('telescope.pickers')
local actions        = require('telescope.actions')
local action_state   = require('telescope.actions.state')
local layout_actions = require('telescope.actions.layout')
local previewers     = require('telescope.previewers')

local util      = require('rc.util')
local map_modes = util.map_modes

local vsplit_key    = util.vsplit_key
local memo_shortcut = util.shortcut_common

-- JSON を整形して出力するユーティリティ（2スペースインデント）
local function json_pretty(val, indent)
  indent = indent or 0
  local t = type(val)
  if t == 'table' then
    -- 配列判定（連続した整数キーのみ）
    local is_array = vim.tbl_islist(val)
    if is_array then
      if #val == 0 then return '[]' end
      local parts = {}
      for _, v in ipairs(val) do
        table.insert(parts, string.rep('  ', indent + 1) .. json_pretty(v, indent + 1))
      end
      return '[\n' .. table.concat(parts, ',\n') .. '\n' .. string.rep('  ', indent) .. ']'
    else
      local keys = vim.tbl_keys(val)
      if #keys == 0 then return '{}' end
      table.sort(keys)
      local parts = {}
      for _, k in ipairs(keys) do
        local v = val[k]
        table.insert(parts, string.rep('  ', indent + 1) .. '"' .. tostring(k) .. '": ' .. json_pretty(v, indent + 1))
      end
      return '{\n' .. table.concat(parts, ',\n') .. '\n' .. string.rep('  ', indent) .. '}'
    end
  elseif t == 'string' then
    return vim.fn.json_encode(val)
  elseif t == 'number' or t == 'boolean' then
    return tostring(val)
  else
    return 'null'
  end
end

local memo_ns          = vim.api.nvim_create_namespace('user_memos')
local memo_file        = vim.fn.expand('~/.vim/memos.json')
local buf_memos        = {}  -- { [bufnr] = { [extmark_id] = { text, color } } }
local memo_loaded_bufs = {}  -- ロード済みバッファの管理
local memo_last_color  = nil -- 直前にカラーピッカーで選択した色（新規メモに引き継ぐ）

-- フィルター定義と適用状態（~/.vim/memo_filters.json に永続化）
local memo_filters_file   = vim.fn.expand('~/.vim/memo_filters.json')
local memo_filters        = {}    -- { { name = 'HOGE', color = '#FFD700' }, ... }
local memo_active_filters = {}    -- 適用中のフィルター名のリスト
local memo_filter_enabled = false -- トグル状態（false なら全メモ表示）
local memo_session_states = {}    -- { [session_name] = { active = {...}, enabled = bool } }

local function memo_filters_load()
  local f = io.open(memo_filters_file, 'r')
  if not f then return end
  local s = f:read('*a'); f:close()
  local ok, t = pcall(vim.fn.json_decode, s)
  if not (ok and type(t) == 'table') then return end
  memo_filters        = type(t.filters)  == 'table' and t.filters  or {}
  memo_active_filters = type(t.active)   == 'table' and t.active   or {}
  memo_filter_enabled = t.enabled == true
  memo_session_states = type(t.sessions) == 'table' and t.sessions or {}
end

local function memo_filters_save()
  local f = io.open(memo_filters_file, 'w')
  if not f then return end
  f:write(json_pretty({
    filters  = memo_filters,
    active   = memo_active_filters,
    enabled  = memo_filter_enabled,
    sessions = memo_session_states,
  }) .. '\n')
  f:close()
end

memo_filters_load()

-- メモ先頭文字列がフィルター文字列と一致するか判定する（前方一致）
local function memo_filter_prefix_match(text, name)
  return text:sub(1, #name) == name
end

-- 適用中フィルターにマッチするか（フィルター無効時・未適用時は常に表示）
local function memo_matches_filter(text)
  if not memo_filter_enabled or #memo_active_filters == 0 then return true end
  for _, name in ipairs(memo_active_filters) do
    if memo_filter_prefix_match(text, name) then return true end
  end
  return false
end

-- メモが属するフィルター（グループ）定義を返す（前方一致で最初に見つかったもの）
local function memo_filter_of(text)
  for _, flt in ipairs(memo_filters) do
    if memo_filter_prefix_match(text, flt.name) then return flt end
  end
  return nil
end

-- パス区切り文字を / に統一する（Windows/GitBash で \ と / が混在する問題を解消）
local function memo_normalize_path(path)
  return path:gsub('\\', '/')
end

-- メモ個別色の highlight group 名を返す（なければ MemoHighlight を使用）
-- ColorScheme 変更後も呼び出し側で再設定できるよう毎回 nvim_set_hl を実行する
local function memo_hl_group(color)
  if not color then return 'MemoHighlight' end
  local name = 'MemoHL_' .. color:sub(2)
  vim.api.nvim_set_hl(0, name, { fg = color, italic = true })
  return name
end

-- メモ文言から改行を除く（末尾は削除、途中は空白に置換）
-- 改行入りの文言は telescope の一覧・プレビューで nvim_buf_set_lines がエラーになるため、読み込み時に正規化する
local function memo_clean_text(text)
  if type(text) ~= 'string' then return text end
  return (text:gsub('[\r\n]+$', ''):gsub('[\r\n]+', ' '))
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
    if type(v) == 'table' then
      for _, e in ipairs(v) do e.text = memo_clean_text(e.text) end
    end
    normalized[memo_normalize_path(k)] = v
  end
  return normalized
end

local function memo_write_json(data)
  local f = io.open(memo_file, 'w')
  if not f then return end
  f:write(json_pretty(data) .. '\n'); f:close()
end

-- 最近使ったメモ（MRU）: 追加・編集・一覧からのジャンプ時に記録する（~/.vim/memo_mru.json）
-- メモの行番号は編集で変わるため、filepath + text で識別し、表示時に memos.json から現在行を引き直す
local memo_mru_file = vim.fn.expand('~/.vim/memo_mru.json')
local MEMO_MRU_MAX  = 100

local function memo_mru_read()
  local f = io.open(memo_mru_file, 'r')
  if not f then return {} end
  local s = f:read('*a'); f:close()
  local ok, t = pcall(vim.fn.json_decode, s)
  if not (ok and type(t) == 'table') then return {} end
  for _, e in ipairs(t) do e.text = memo_clean_text(e.text) end
  return t
end

local function memo_mru_write(list)
  local f = io.open(memo_mru_file, 'w')
  if not f then return end
  f:write(json_pretty(list) .. '\n'); f:close()
end

-- old_text: 編集・リネームで文言が変わった場合の旧文言（旧エントリを置き換える）
local function memo_mru_touch(filepath, line, text, old_text)
  if not filepath or filepath == '' or not text or text == '' then return end
  filepath = memo_normalize_path(filepath)
  local list = {}
  for _, e in ipairs(memo_mru_read()) do
    if not (e.filepath == filepath and (e.text == text or e.text == old_text)) then
      table.insert(list, e)
    end
  end
  table.insert(list, 1, { filepath = filepath, line = line, text = text, used_at = os.time() })
  while #list > MEMO_MRU_MAX do table.remove(list) end
  memo_mru_write(list)
end

local function memo_mru_remove(filepath, text)
  local list = {}
  for _, e in ipairs(memo_mru_read()) do
    if not (e.filepath == filepath and e.text == text) then table.insert(list, e) end
  end
  memo_mru_write(list)
end

-- メモの表示色を解決する（フィルターグループ色 → メモ個別色 → デフォルト）
local function memo_display_color(text, color)
  local flt = memo_filter_of(text)
  return (flt and flt.color) or color
end

-- extmark を配置してバッファ内メモテーブルに登録する
-- フィルター非適合メモは virt_lines を付けず extmark のみ配置する
-- （extmark を残すことで非表示中も行編集に位置が追従し、保存時の位置ずれを防ぐ）
local function memo_set_extmark(bufnr, line0, text, color)
  local opts = {}
  if memo_matches_filter(text) then
    opts.virt_lines       = { { { '  📝 ' .. text, memo_hl_group(memo_display_color(text, color)) } } }
    opts.virt_lines_above = false
  end
  local id = vim.api.nvim_buf_set_extmark(bufnr, memo_ns, line0, 0, opts)
  if not buf_memos[bufnr] then buf_memos[bufnr] = {} end
  buf_memos[bufnr][id] = { text = text, color = color }
  return id
end

-- フィルター状態に合わせて既存 extmark の virt_lines を付け外しする
-- （id 指定の nvim_buf_set_extmark で上書きし、位置と id は維持する）
local function memo_refresh_buf(bufnr)
  local ids = buf_memos[bufnr]
  if not ids then return end
  for id, m in pairs(ids) do
    local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, memo_ns, id, {})
    if pos and pos[1] then
      local opts = { id = id }
      if memo_matches_filter(m.text) then
        opts.virt_lines       = { { { '  📝 ' .. m.text, memo_hl_group(memo_display_color(m.text, m.color)) } } }
        opts.virt_lines_above = false
      end
      vim.api.nvim_buf_set_extmark(bufnr, memo_ns, pos[1], 0, opts)
    end
  end
end

local function memo_refresh_all_bufs()
  for bufnr in pairs(buf_memos) do
    if vim.api.nvim_buf_is_valid(bufnr) then memo_refresh_buf(bufnr) end
  end
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
  for id, m in pairs(ids) do
    local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, memo_ns, id, {})
    if pos and pos[1] then
      local entry = { line = pos[1] + 1, text = m.text }  -- JSON は 1-indexed
      if m.color then entry.color = m.color end
      table.insert(entries, entry)
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
      memo_set_extmark(bufnr, e.line - 1, e.text, e.color)  -- extmark は 0-indexed
    end
  end, 100)
end

-- フィルター選択ポップアップ付きの input()（定義はフィルター機能の箇所）
local memo_input_with_filters

-- 現在行のメモを追加または編集する
-- 入力中は <C-k>/<C-j> でフィルターを選ぶと「フィルター名 + 元の文言」に置き換わり、<CR> でそのまま確定する
local function memo_add_or_edit()
  local bufnr = vim.api.nvim_get_current_buf()
  local line0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  -- 現在行に既存メモがあれば取得する
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, memo_ns, { line0, 0 }, { line0, -1 }, {})
  local existing_id, existing_text, existing_color
  if #marks > 0 then
    existing_id = marks[1][1]
    local m = (buf_memos[bufnr] or {})[existing_id]
    existing_text  = m and m.text  or ''
    existing_color = m and m.color or nil
  end
  -- フィルター適用中の新規メモは先頭にフィルター文字列を事前入力する
  local default_text = existing_text
  if not default_text and memo_filter_enabled and memo_active_filters[1] then
    default_text = memo_active_filters[1] .. ' '
  end
  local input = memo_input_with_filters('Memo: ', default_text or '', { with_text = true })
  vim.cmd('redraw')
  if input == '' then return end
  if existing_id then
    vim.api.nvim_buf_del_extmark(bufnr, memo_ns, existing_id)
    if buf_memos[bufnr] then buf_memos[bufnr][existing_id] = nil end
  end
  -- 新規メモは直前のカラーピッカー選択色を引き継ぐ
  local color = existing_color or memo_last_color
  memo_set_extmark(bufnr, line0, input, color)
  memo_flush_buf(bufnr)
  memo_mru_touch(vim.api.nvim_buf_get_name(bufnr), line0 + 1, input, existing_text)
end

-- 定型メモのテンプレート
-- callgraph ツール（etc/callgraph.sh）はここの text を抽出キーワードとして受け取る
local memo_templates = {
  {
    text  = '検索: この関数を起点とした呼び出しを調べる',
    color = '#00FF7F',  -- 起点メモを通常メモと見分けるための固定色
  },
}

-- 定型メモを現在行に追加する（テンプレートが1件ならピッカーを出さず即挿入）
local function memo_add_template()
  local bufnr = vim.api.nvim_get_current_buf()
  local line0 = vim.api.nvim_win_get_cursor(0)[1] - 1

  local function insert(tpl)
    -- 同じ行の既存メモは置き換える（memo_add_or_edit と同じ挙動）
    local marks = vim.api.nvim_buf_get_extmarks(bufnr, memo_ns, { line0, 0 }, { line0, -1 }, {})
    for _, m in ipairs(marks) do
      vim.api.nvim_buf_del_extmark(bufnr, memo_ns, m[1])
      if buf_memos[bufnr] then buf_memos[bufnr][m[1]] = nil end
    end
    memo_set_extmark(bufnr, line0, tpl.text, tpl.color)
    memo_flush_buf(bufnr)
    memo_mru_touch(vim.api.nvim_buf_get_name(bufnr), line0 + 1, tpl.text)
    vim.notify('Memo: ' .. tpl.text, vim.log.levels.INFO)
  end

  if #memo_templates == 1 then insert(memo_templates[1]); return end

  pickers.new({}, {
    prompt_title = '📝 Memo Template  <CR>=挿入',
    finder = finders.new_table({
      results     = memo_templates,
      entry_maker = function(t)
        return { value = t, display = t.text, ordinal = t.text }
      end,
    }),
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local sel = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if sel then vim.schedule(function() insert(sel.value) end) end
      end)
      return true
    end,
    layout_strategy = 'center',
    layout_config   = { width = 70, height = 10 },
  }):find()
end

-- メモテキストからフィルター prefix を除去する（フィルター適用中のみ）
local function memo_strip_filter_prefix(text)
  if not memo_filter_enabled or #memo_active_filters == 0 then return text end
  for _, name in ipairs(memo_active_filters) do
    if memo_filter_prefix_match(text, name) then
      local stripped = text:sub(#name + 1):gsub('^%s+', '')
      return stripped ~= '' and stripped or text
    end
  end
  return text
end

-- 現在行のメモテキストをクリップボードにコピーする
-- フィルター適用中はフィルター文字列を除去してコピーする
local function memo_copy_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local line0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  local marks  = vim.api.nvim_buf_get_extmarks(bufnr, memo_ns, { line0, 0 }, { line0, -1 }, {})
  if #marks == 0 then vim.notify('No memo on this line', vim.log.levels.INFO); return end
  local m = (buf_memos[bufnr] or {})[marks[1][1]]
  if not m then return end
  local copy_text = memo_strip_filter_prefix(m.text)
  vim.fn.setreg('+', copy_text)
  vim.fn.setreg('"', copy_text)
  vim.notify('Copied: ' .. copy_text)
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
    -- ヘッダにメモテキストとファイルパスを表示
    local header = { '📝  ' .. (memo_clean_text(text) or ''), filepath, string.rep('─', 60), '' }
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
  memo_mru_touch(sel.value.filepath, sel.value.line, sel.value.text)
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

-- メモ一覧の切り替え（どの一覧からでも <M-1>〜<M-5> で直接切り替える。入力中の絞り込み文字は引き継ぐ）
-- open は各一覧関数の定義後に登録する（open(default_text) は一覧を開いたら true、メモが無ければ nil を返す）
-- 並び順 = キー番号（<M-1> から順に割り当てる）。id で各一覧から参照する
local memo_lists = {
  { id = 'recent',  label = 'Recent' },   -- <leader>mm
  { id = 'current', label = 'Current' },  -- <leader>ll
  { id = 'buffers', label = 'Buffers' },  -- <leader>mb
  { id = 'all',     label = 'All' },      -- <leader>ml
  { id = 'active',  label = 'Active' },   -- <leader>mv
}
for i, l in ipairs(memo_lists) do l.key = '<M-' .. i .. '>' end

-- prompt_title に付ける切り替え案内（現在の一覧は [ ] で囲む）
local function memo_switch_label(current)
  local parts = {}
  for _, l in ipairs(memo_lists) do
    table.insert(parts, l.key .. (l.id == current and ('[' .. l.label .. ']') or l.label))
  end
  return '  ' .. table.concat(parts, ' ')
end

-- 切り替えキーを登録する。切り替え先にメモが無い場合は元の一覧を開き直す
local function memo_attach_switch(map, current)
  local back
  for _, l in ipairs(memo_lists) do
    if l.id == current then back = l end
  end
  for _, l in ipairs(memo_lists) do
    map_modes(map, l.key, function(b)
      if l.id == current then return end
      local query = action_state.get_current_picker(b):_get_prompt()
      actions.close(b)
      vim.schedule(function()
        if not l.open(query) then back.open(query) end
      end)
    end)
  end
end

-- メモピッカー共通キーマップ（<CR> <C-d> <C-l> <C-t> <C-v> <C-h>）
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
    map_modes(map, '<C-d>',    delete_memo)
    map_modes(map, '<C-t>',    function(b) memo_open_entry(b, 'tabedit') end)
    map_modes(map, vsplit_key, function(b) memo_open_entry(b, 'vsplit') end)
    map_modes(map, '<C-h>',    function(b) memo_open_entry(b, 'split') end)
    map_modes(map, '<C-f>',    layout_actions.toggle_preview)
    if extra then extra(prompt_bufnr, map) end
    return true
  end
end

-- カラーピッカーを表示して選択色を callback(hex) で返す
local function show_color_picker(callback)
  local square = '██ '           -- U+2588 × 2 + space（各3バイト = 計7バイト）
  local sq_len = #square         -- ハイライト範囲のバイト終端
  local color_presets = {
    { name = 'Gold',   hex = '#FFD700' },
    { name = 'Coral',  hex = '#FF7F50' },
    { name = 'Sky',    hex = '#87CEEB' },
    { name = 'Lime',   hex = '#00FF7F' },
    { name = 'Violet', hex = '#EE82EE' },
    { name = 'Orange', hex = '#FFA500' },
    { name = 'Pink',   hex = '#FFB6C1' },
    { name = 'Cyan',   hex = '#00FFFF' },
    { name = 'Custom', hex = nil },
  }
  -- 各色のハイライトグループを事前定義
  for _, c in ipairs(color_presets) do
    if c.hex then
      vim.api.nvim_set_hl(0, 'ColorPickerHL_' .. c.hex:sub(2), { fg = c.hex })
    end
  end
  pickers.new({}, {
    prompt_title = 'Memo Color',
    finder = finders.new_table({
      results     = color_presets,
      entry_maker = function(item)
        local disp, hl
        if item.hex then
          disp = square .. item.name .. '  ' .. item.hex
          hl   = { { { 0, sq_len }, 'ColorPickerHL_' .. item.hex:sub(2) } }
        else
          disp = '   ' .. item.name .. '  (入力)'
          hl   = {}
        end
        return {
          value   = item,
          display = function() return disp, hl end,
          ordinal = item.name,
        }
      end,
    }),
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(pb)
      -- results ウィンドウの選択行ハイライトを fg なし版に差し替え（着色四角を維持するため）
      vim.schedule(function()
        local picker = action_state.get_current_picker(pb)
        if picker and picker.results_win and vim.api.nvim_win_is_valid(picker.results_win) then
          vim.wo[picker.results_win].winhighlight = 'TelescopeSelection:ColorPickerSelection'
        end
      end)
      actions.select_default:replace(function()
        local sel = action_state.get_selected_entry()
        actions.close(pb)
        vim.schedule(function()
          local hex = sel.value.hex
          if not hex then
            hex = vim.fn.input('Color (#RRGGBB): ')
            if hex == '' then return end
            if not hex:match('^#%x%x%x%x%x%x$') then
              vim.notify('Invalid color: ' .. hex, vim.log.levels.ERROR); return
            end
          end
          callback(hex)
        end)
      end)
      return true
    end,
    layout_strategy = 'center',
    layout_config   = { width = 40, height = 14 },
  }):find()
end

-- カーソル位置にあるメモの色をカラーピッカーで変更する
-- フィルター（グループ）に属するメモはグループ色として保存し、同グループの全メモに反映する
local function memo_change_color_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local line0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, memo_ns, { line0, 0 }, { line0, -1 }, {})
  if #marks == 0 then vim.notify('No memo on this line', vim.log.levels.INFO); return end
  local id  = marks[1][1]
  local m   = (buf_memos[bufnr] or {})[id]
  if not m then return end
  local flt = memo_filter_of(m.text)
  if flt then
    show_color_picker(function(hex)
      flt.color = hex
      memo_filters_save()
      memo_refresh_all_bufs()
      vim.notify('Filter color: ' .. flt.name .. ' → ' .. hex)
    end)
    return
  end
  -- どのフィルターにも属さないメモは従来どおり個別色を変更する
  local text     = m.text
  local ln       = line0 + 1  -- JSON は 1-indexed
  local filepath = memo_normalize_path(vim.api.nvim_buf_get_name(bufnr))
  show_color_picker(function(hex)
    memo_last_color = hex
    -- JSON を更新
    local store = memo_read_json()
    if store[filepath] then
      for _, e in ipairs(store[filepath]) do
        if e.line == ln then e.color = hex; break end
      end
      memo_write_json(store)
    end
    -- バッファ内 extmark を更新
    vim.api.nvim_buf_del_extmark(bufnr, memo_ns, id)
    if buf_memos[bufnr] then buf_memos[bufnr][id] = nil end
    memo_set_extmark(bufnr, line0, text, hex)
  end)
end

-- Telescope でメモ一覧を表示する
-- filter_only: true ならフィルター適用中のメモのみ表示
local function memo_list(filter_only, default_text)
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
        color    = e.color,
      })
    end
    ::continue::
  end
  -- フィルター適用中はマッチするメモのみに絞り込む
  if filter_only then
    local filtered = {}
    for _, r in ipairs(results) do
      if memo_matches_filter(r.text) then table.insert(filtered, r) end
    end
    results = filtered
  end
  table.sort(results, function(a, b)
    if a.filepath ~= b.filepath then return a.filepath < b.filepath end
    return a.line < b.line
  end)
  -- メモ列の最大表示幅を計算してファイル名列を縦揃えする（全角対応）
  local max_tw = 0
  for _, r in ipairs(results) do
    local w = vim.fn.strdisplaywidth(r.text)
    if w > max_tw then max_tw = w end
  end
  for _, r in ipairs(results) do
    local pad = string.rep(' ', max_tw - vim.fn.strdisplaywidth(r.text))
    r.display = r.text .. pad .. '  ' .. vim.fn.fnamemodify(r.filepath, ':t')
  end

  local title = filter_only
    and ('📝 Filtered Memos [' .. table.concat(memo_active_filters, ', ') .. ']  <CR>=ジャンプ <C-d>=削除 <C-r>=リネーム')
    or  '📝 Memos  <CR>=ジャンプ <C-d>=削除 <C-r>=リネーム'
  pickers.new({}, {
    prompt_title  = title .. memo_switch_label('all'),
    results_title = memo_shortcut,
    default_text  = default_text,
    finder = finders.new_table({
      results = results,
      entry_maker = function(e)
        return { value = e, display = e.display, ordinal = e.display, filename = e.filepath, lnum = e.line }
      end,
    }),
    sorter    = make_memo_sorter(results),
    previewer = memo_previewer,
    attach_mappings = make_memo_attach_mappings(function(prompt_bufnr, map)
      memo_attach_switch(map, 'all')
      local function rename_memo()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local fp, ln = sel.value.filepath, sel.value.line
        actions.close(prompt_bufnr)
        vim.schedule(function()
          local new_text = vim.fn.input('Memo: ', sel.value.text)
          vim.cmd('redraw')
          if new_text == '' or new_text == sel.value.text then return end
          memo_mru_touch(fp, ln, new_text, sel.value.text)
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
              local old_color = (buf_memos[bufnr][m[1]] or {}).color
              vim.api.nvim_buf_del_extmark(bufnr, memo_ns, m[1])
              buf_memos[bufnr][m[1]] = nil
              memo_set_extmark(bufnr, ln - 1, new_text, old_color)
            end
          end
          memo_list(filter_only)
        end)
      end
      map_modes(map, '<C-r>', rename_memo)
    end),
  }):find()
  return true
end

-- メモのハイライト定義（colorscheme 変更後も維持する）
local memo_color_file = vim.fn.expand('~/.vim/memo_color.json')

local function memo_color_load()
  local fh = io.open(memo_color_file, 'r')
  if not fh then return '#FFD700' end
  local raw = fh:read('*a')
  fh:close()
  local ok, obj = pcall(vim.fn.json_decode, raw)
  if ok and type(obj) == 'table' and type(obj.color) == 'string' then
    return obj.color
  end
  return '#FFD700'
end

local function memo_color_save(hex)
  local fh = io.open(memo_color_file, 'w')
  if fh then
    fh:write(json_pretty({ color = hex }) .. '\n')
    fh:close()
  end
end

local function restore_memo_hl()
  vim.api.nvim_set_hl(0, 'MemoHighlight', { fg = memo_color_load(), italic = true })
  -- JSON に保存された個別色の highlight group を再定義する（ColorScheme 変更後に失われるため）
  local data = memo_read_json()
  for _, entries in pairs(data) do
    for _, e in ipairs(entries) do
      if e.color then
        vim.api.nvim_set_hl(0, 'MemoHL_' .. e.color:sub(2), { fg = e.color, italic = true })
      end
    end
  end
  -- フィルターグループ色の highlight group も再定義する
  for _, flt in ipairs(memo_filters) do
    if flt.color then
      vim.api.nvim_set_hl(0, 'MemoHL_' .. flt.color:sub(2), { fg = flt.color, italic = true })
    end
  end
end
restore_memo_hl()
vim.api.nvim_create_autocmd({ 'VimEnter', 'ColorScheme' }, { callback = restore_memo_hl })

local function pick_memo_color()
  show_color_picker(function(hex)
    vim.api.nvim_set_hl(0, 'MemoHighlight', { fg = hex, italic = true })
    memo_color_save(hex)
  end)
end
vim.api.nvim_create_user_command('MemoColor', pick_memo_color, {})

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
local function memo_list_current(default_text)
  local bufnr    = vim.api.nvim_get_current_buf()
  local filepath = memo_normalize_path(vim.api.nvim_buf_get_name(bufnr))
  if filepath == '' then vim.notify('No file', vim.log.levels.INFO); return end
  local entries = memo_read_json()[filepath] or {}
  local results = {}
  for _, e in ipairs(entries) do
    table.insert(results, { filepath = filepath, line = e.line, text = e.text, color = e.color,
      display = string.format('%4d  %s', e.line, e.text) })
  end
  if #results == 0 then vim.notify('No memos in this file', vim.log.levels.INFO); return end
  pickers.new({}, {
    prompt_title    = '📝 Memos (current file)  <CR>=ジャンプ <C-d>=削除' .. memo_switch_label('current'),
    results_title   = memo_shortcut,
    default_text    = default_text,
    finder          = finders.new_table({
      results     = results,
      entry_maker = function(e)
        return { value = e, display = e.display, ordinal = e.display, filename = e.filepath, lnum = e.line }
      end,
    }),
    sorter          = make_memo_sorter(results),
    previewer       = memo_previewer,
    attach_mappings = make_memo_attach_mappings(function(_, map) memo_attach_switch(map, 'current') end),
  }):find()
  return true
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
local function memo_list_buffers(default_text)
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
          color    = e.color,
        })
      end
    end
  end
  table.sort(results, function(a, b)
    if a.filepath ~= b.filepath then return a.filepath < b.filepath end
    return a.line < b.line
  end)
  -- メモ列の最大表示幅を計算してファイル名列を縦揃えする（全角対応）
  local max_tw = 0
  for _, r in ipairs(results) do
    local w = vim.fn.strdisplaywidth(r.text)
    if w > max_tw then max_tw = w end
  end
  for _, r in ipairs(results) do
    local pad = string.rep(' ', max_tw - vim.fn.strdisplaywidth(r.text))
    r.display = r.text .. pad .. '  ' .. vim.fn.fnamemodify(r.filepath, ':t')
  end

  if #results == 0 then
    vim.notify('No memos in open buffers', vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title  = '📝 Buffer Memos  <CR>=ジャンプ <C-d>=削除' .. memo_switch_label('buffers'),
    results_title = memo_shortcut,
    default_text  = default_text,
    finder = finders.new_table({
      results = results,
      entry_maker = function(e)
        return { value = e, display = e.display, ordinal = e.display, filename = e.filepath, lnum = e.line }
      end,
    }),
    sorter    = make_memo_sorter(results),
    previewer = memo_previewer,
    attach_mappings = function(prompt_bufnr, map)
      memo_attach_switch(map, 'buffers')
      -- <CR>: 既存ウィンドウへジャンプ（バッファファイルのため通常は存在する）
      local function jump_to_win()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local filepath = sel.value.filepath
        local lnum     = sel.value.line
        actions.close(prompt_bufnr)
        memo_mru_touch(filepath, lnum, sel.value.text)
        -- vim.schedule だと Telescope のウィンドウ復元が間に合わないため
        -- defer_fn で少し待ってから処理する
        vim.defer_fn(function()
          -- bufwinid は現在タブのみ対象のため nvim_list_wins で全タブを横断検索
          local bufnr = vim.fn.bufnr(filepath)
          local target_win = nil
          if bufnr ~= -1 then
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_get_buf(win) == bufnr then
                target_win = win
                break
              end
            end
          end
          if target_win then
            vim.api.nvim_set_current_win(target_win)
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
      map_modes(map, '<C-d>',    delete_memo)
      map_modes(map, '<C-t>',    function(b) memo_open_entry(b, 'tabedit') end)
      map_modes(map, vsplit_key, function(b) memo_open_entry(b, 'vsplit') end)
      map_modes(map, '<C-h>',    function(b) memo_open_entry(b, 'split') end)
      map_modes(map, '<C-f>',    layout_actions.toggle_preview)
      return true
    end,
    -- フロートレイアウト: 既存の vsplit ウィンドウを破壊しないため center を使用
    layout_strategy = 'center',
    layout_config   = { width = 0.8, height = 0.7, preview_cutoff = 1 },
  }):find()
  return true
end


-- 現在アクティブな（バッファに表示中の）メモのみを一覧表示する
-- buf_memos 上のメモのうちフィルターに適合するもの（= 画面上で仮想行として見えているもの）を対象
local function memo_list_active(default_text)
  local results = {}
  for bufnr, ids in pairs(buf_memos) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local filepath = memo_normalize_path(vim.api.nvim_buf_get_name(bufnr))
      if filepath ~= '' then
        for id, m in pairs(ids) do
          if memo_matches_filter(m.text) then
            local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, memo_ns, id, {})
            if pos and pos[1] then
              table.insert(results, {
                filepath = filepath,
                line     = pos[1] + 1,
                text     = m.text,
                color    = m.color,
              })
            end
          end
        end
      end
    end
  end

  if #results == 0 then
    vim.notify('No active memos', vim.log.levels.INFO)
    return
  end

  table.sort(results, function(a, b)
    if a.filepath ~= b.filepath then return a.filepath < b.filepath end
    return a.line < b.line
  end)

  local max_tw = 0
  for _, r in ipairs(results) do
    local w = vim.fn.strdisplaywidth(r.text)
    if w > max_tw then max_tw = w end
  end
  for _, r in ipairs(results) do
    local pad = string.rep(' ', max_tw - vim.fn.strdisplaywidth(r.text))
    r.display = r.text .. pad .. '  ' .. vim.fn.fnamemodify(r.filepath, ':t')
  end

  local title = '📝 Active Memos'
  if memo_filter_enabled and #memo_active_filters > 0 then
    title = title .. ' [' .. table.concat(memo_active_filters, ', ') .. ']'
  end
  title = title .. '  <CR>=ジャンプ <C-d>=削除' .. memo_switch_label('active')

  pickers.new({}, {
    prompt_title  = title,
    results_title = memo_shortcut,
    default_text  = default_text,
    finder = finders.new_table({
      results = results,
      entry_maker = function(e)
        return { value = e, display = e.display, ordinal = e.display, filename = e.filepath, lnum = e.line }
      end,
    }),
    sorter    = make_memo_sorter(results),
    previewer = memo_previewer,
    attach_mappings = function(prompt_bufnr, map)
      memo_attach_switch(map, 'active')
      local function jump_to_win()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local filepath = sel.value.filepath
        local lnum     = sel.value.line
        actions.close(prompt_bufnr)
        memo_mru_touch(filepath, lnum, sel.value.text)
        vim.defer_fn(function()
          local bn = vim.fn.bufnr(filepath)
          local target_win = nil
          if bn ~= -1 then
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_get_buf(win) == bn then
                target_win = win
                break
              end
            end
          end
          if target_win then
            vim.api.nvim_set_current_win(target_win)
          else
            vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
          end
          vim.api.nvim_win_set_cursor(0, { lnum, 0 })
          vim.cmd('normal! zz')
        end, 50)
      end
      actions.select_default:replace(jump_to_win)
      local function delete_memo()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local picker = action_state.get_current_picker(prompt_bufnr)
        memo_delete_from_store(sel.value.filepath, sel.value.line)
        picker:delete_selection(function() vim.notify('Memo deleted') end)
      end
      map_modes(map, '<C-d>',    delete_memo)
      map_modes(map, '<C-t>',    function(b) memo_open_entry(b, 'tabedit') end)
      map_modes(map, vsplit_key, function(b) memo_open_entry(b, 'vsplit') end)
      map_modes(map, '<C-h>',    function(b) memo_open_entry(b, 'split') end)
      map_modes(map, '<C-f>',    layout_actions.toggle_preview)
      return true
    end,
    layout_strategy = 'center',
    layout_config   = { width = 0.8, height = 0.7, preview_cutoff = 1 },
  }):find()
  return true
end

-- 最近使ったメモ（MRU）を新しい順に一覧表示する（git root 配下のみ。git 管理外なら全件）
-- 削除済みのメモは表示せず、MRU からも取り除く
local function memo_list_mru(default_text)
  local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
  local has_git  = git_root ~= '' and not git_root:find('fatal')
  local gr_norm  = has_git
    and vim.fn.fnamemodify(git_root, ':p'):gsub('[/\\]$', ''):gsub('\\', '/') or nil

  local store   = memo_read_json()
  local mru     = memo_mru_read()
  local alive   = {}
  local results = {}
  for _, e in ipairs(mru) do
    -- 同じ文言のメモを探し、記録時の行に最も近いものを現在位置とする
    -- ロード済みバッファは extmark の現在行を使う（memos.json の行はバッファ破棄時まで更新されないため）
    local candidates = {}
    local bn = vim.fn.bufnr(e.filepath)
    if bn ~= -1 and buf_memos[bn] then
      for id, m in pairs(buf_memos[bn]) do
        local pos = vim.api.nvim_buf_get_extmark_by_id(bn, memo_ns, id, {})
        if pos and pos[1] then table.insert(candidates, { line = pos[1] + 1, text = m.text }) end
      end
    else
      candidates = store[e.filepath] or {}
    end
    local line
    for _, m in ipairs(candidates) do
      if m.text == e.text and (not line or math.abs(m.line - e.line) < math.abs(line - e.line)) then
        line = m.line
      end
    end
    if line then
      table.insert(alive, e)
      local fp_norm = vim.fn.fnamemodify(e.filepath, ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
      if not gr_norm or fp_norm:find(gr_norm, 1, true) == 1 then
        table.insert(results, { filepath = e.filepath, line = line, text = e.text, used_at = e.used_at })
      end
    end
  end
  if #alive ~= #mru then memo_mru_write(alive) end

  if #results == 0 then
    vim.notify('No recent memos', vim.log.levels.INFO)
    return
  end

  -- メモ列の最大表示幅を計算してファイル名列を縦揃えする（全角対応）
  -- 文言に改行が含まれると telescope の結果バッファの行数がずれてエラーになるため、表示用は空白に置き換える
  local max_tw = 0
  for _, r in ipairs(results) do
    r.disp_text = (r.text:gsub('[\r\n]+', ' '))
    local w = vim.fn.strdisplaywidth(r.disp_text)
    if w > max_tw then max_tw = w end
  end
  for i, r in ipairs(results) do
    local pad = string.rep(' ', max_tw - vim.fn.strdisplaywidth(r.disp_text))
    r.rank    = i
    r.display = os.date('%m/%d %H:%M', r.used_at or 0) .. '  ' .. r.disp_text .. pad .. '  ' .. vim.fn.fnamemodify(r.filepath, ':t')
  end

  -- 新しい順を保ったまま prompt で絞り込む（スコアが低いほどプロンプト寄り = 新しいものが選択位置に来る）
  local fzy = require('telescope.algos.fzy')
  local mru_sorter = require('telescope.sorters').Sorter:new({
    discard = false,
    scoring_function = function(_, prompt, line, entry)
      if prompt ~= '' and not fzy.has_match(prompt:lower(), (line or ''):lower()) then return -1 end
      return entry.value.rank
    end,
  })

  pickers.new({}, {
    prompt_title  = '📝 Recent Memos  <CR>=ジャンプ <C-d>=MRUから除外' .. memo_switch_label('recent'),
    results_title = memo_shortcut,
    default_text  = default_text,
    finder = finders.new_table({
      results = results,
      entry_maker = function(e)
        return { value = e, display = e.display, ordinal = e.disp_text .. ' ' .. e.filepath, filename = e.filepath, lnum = e.line }
      end,
    }),
    sorter    = mru_sorter,
    previewer = memo_previewer,
    attach_mappings = make_memo_attach_mappings(function(prompt_bufnr, map)
      memo_attach_switch(map, 'recent')
      -- <C-d>: メモ自体は消さず MRU からのみ除外する（共通の「メモ削除」を上書き）
      map_modes(map, '<C-d>', function()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        memo_mru_remove(sel.value.filepath, sel.value.text)
        action_state.get_current_picker(prompt_bufnr):delete_selection(function() vim.notify('Removed from recent memos') end)
      end)
    end),
  }):find()
  return true
end

local memo_list_openers = {
  recent  = memo_list_mru,
  current = memo_list_current,
  buffers = memo_list_buffers,
  all     = function(q) return memo_list(false, q) end,
  active  = memo_list_active,
}
for _, l in ipairs(memo_lists) do l.open = memo_list_openers[l.id] end

-- 候補テキストファイルからメモを選択して現在行に追加する
-- 候補ファイル: ~/.vim/memo_candidates.txt（1行1候補）
local memo_candidates_path = vim.fn.expand('~/.vim/memo_candidates.txt')

local function memo_select_from_list()
  local f = io.open(memo_candidates_path, 'r')
  if not f then
    vim.notify('候補ファイルが見つかりません: ' .. memo_candidates_path, vim.log.levels.ERROR)
    return
  end
  local candidates = {}
  for line in f:lines() do
    if line ~= '' then table.insert(candidates, line) end
  end
  f:close()
  if #candidates == 0 then
    vim.notify('候補ファイルが空です: ' .. memo_candidates_path, vim.log.levels.INFO)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local line0 = vim.api.nvim_win_get_cursor(0)[1] - 1

  pickers.new({}, {
    prompt_title = '📝 Memo 候補  <CR>=選択して編集',
    finder = finders.new_table({
      results     = candidates,
      entry_maker = function(c)
        return { value = c, display = c, ordinal = c }
      end,
    }),
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local sel = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.schedule(function()
          local selected_text = sel and sel.value or ''
          -- フィルター適用中は先頭にフィルター文字列を付与して編集開始する
          if memo_filter_enabled and memo_active_filters[1]
              and not memo_filter_prefix_match(selected_text, memo_active_filters[1]) then
            selected_text = memo_active_filters[1] .. ' ' .. selected_text
          end
          local input = vim.fn.input('Memo: ', selected_text):gsub('[\r\n]', '')
          vim.cmd('redraw')
          if input == '' then return end
          -- 既存メモは置き換える
          local marks = vim.api.nvim_buf_get_extmarks(bufnr, memo_ns, { line0, 0 }, { line0, -1 }, {})
          for _, m in ipairs(marks) do
            vim.api.nvim_buf_del_extmark(bufnr, memo_ns, m[1])
            if buf_memos[bufnr] then buf_memos[bufnr][m[1]] = nil end
          end
          local color = memo_last_color
          memo_set_extmark(bufnr, line0, input, color)
          memo_flush_buf(bufnr)
          memo_mru_touch(vim.api.nvim_buf_get_name(bufnr), line0 + 1, input)
        end)
      end)
      return true
    end,
    layout_strategy = 'center',
    layout_config   = { width = 70, height = 20 },
  }):find()
end

-- airline ステータスにフィルター状態を表示する
local function memo_update_airline()
  if memo_filter_enabled and #memo_active_filters > 0 then
    vim.g.airline_section_z = '%{g:memo_filter_status}'
    vim.g.memo_filter_status = 'Filter: ' .. table.concat(memo_active_filters, ', ')
  else
    vim.g.airline_section_z = ''
    vim.g.memo_filter_status = ''
  end
  pcall(vim.cmd, 'AirlineRefresh')
end
vim.api.nvim_create_autocmd('VimEnter', { callback = memo_update_airline })

-- フィルターを登録して適用する共通処理（未定義なら定義一覧に追加する）
local function memo_filter_activate(name)
  local found
  for _, flt in ipairs(memo_filters) do
    if flt.name == name then found = flt; break end
  end
  if not found then
    found = { name = name }
    table.insert(memo_filters, found)
  end
  found.used_at = os.time()  -- フィルターポップアップの並び順（最近使った順）に使う
  memo_active_filters = { name }
  memo_filter_enabled = true
  memo_filters_save()
  memo_refresh_all_bufs()
  memo_update_airline()
  vim.notify('Memo filter: ' .. name)
end

-- フィルターを最近使った順の逆（古い順）に並べる（最新が末尾 = ポップアップの最下行）
local function memo_filters_by_recent()
  local list = {}
  for i, flt in ipairs(memo_filters) do table.insert(list, { flt = flt, i = i }) end
  table.sort(list, function(a, b)
    local ua, ub = a.flt.used_at or 0, b.flt.used_at or 0
    if ua ~= ub then return ua < ub end
    return a.i < b.i
  end)
  return vim.tbl_map(function(x) return x.flt end, list)
end

-- フィルター 1 行分の表示（色アイコン + 名前 + 適用中なら ※）と色アイコンのハイライト
local MEMO_SQUARE = '██'
local function memo_filter_line(flt, row0, lines, hls)
  local hex = flt.color or memo_color_load()
  local hl  = 'ColorPickerHL_' .. hex:sub(2)
  vim.api.nvim_set_hl(0, hl, { fg = hex })
  local active = vim.tbl_contains(memo_active_filters, flt.name)
  table.insert(lines, ' ' .. MEMO_SQUARE .. ' ' .. flt.name .. (active and '※' or ''))
  table.insert(hls, { row0, 1, 1 + #MEMO_SQUARE, hl })
end

-- コマンドライン直上にポップアップを出す（下端ボーダーがコマンドラインの 1 行上に来る）
local MEMO_POPUP_MAX = 10
local function memo_popup_open(buf, nlines, title, enter)
  local width = 40
  for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    width = math.max(width, vim.fn.strdisplaywidth(l) + 2)
  end
  width = math.min(math.max(width, vim.fn.strdisplaywidth(title) + 4), vim.o.columns - 2)
  local height = math.min(nlines, MEMO_POPUP_MAX)
  local win = vim.api.nvim_open_win(buf, enter, {
    relative  = 'editor',
    row       = math.max(0, vim.o.lines - vim.o.cmdheight - (height + 2)),
    col       = 0,
    width     = width,
    height    = height,
    style     = 'minimal',
    border    = 'rounded',
    title     = title,
    focusable = enter,
    zindex    = 200,
  })
  vim.wo[win].cursorline   = true
  vim.wo[win].winhighlight = 'Normal:PopupText,FloatBorder:FloatBorder,FloatTitle:PopupTitle,CursorLine:ColorPickerSelection'
  return win
end

local function memo_popup_buf(lines, hls)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for _, h in ipairs(hls) do vim.api.nvim_buf_add_highlight(buf, -1, h[4], h[1], h[2], h[3]) end
  vim.bo[buf].modifiable = false
  return buf
end

-- input() の間だけコマンドラインに一時マッピングを張り、終了後に元のマッピングへ戻す
local function memo_with_cmap(maps, fn)
  local saved = {}
  for key, cb in pairs(maps) do
    saved[key] = vim.fn.maparg(key, 'c', false, true)
    vim.keymap.set('c', key, cb)
  end
  local ok, res = pcall(fn)
  for key, m in pairs(saved) do
    pcall(vim.keymap.del, 'c', key)
    if m and not vim.tbl_isempty(m) then vim.fn.mapset('c', false, m) end
  end
  return ok and res or ''
end

-- メモ先頭の登録済みフィルター名（+ 続く空白）を取り除く（最長一致。フィルター名だけのメモはそのまま）
local function memo_strip_any_filter_prefix(text)
  local best = 0
  for _, flt in ipairs(memo_filters) do
    local n = #flt.name
    if n > best and memo_filter_prefix_match(text, flt.name) then
      local next_ch = text:sub(n + 1, n + 1)
      if next_ch == '' or next_ch:match('%s') then best = n end
    end
  end
  if best == 0 then return text end
  return (text:sub(best + 1):gsub('^%s+', ''))
end

-- フィルター選択ポップアップ付きの input()
-- <C-k>/<C-j>: 登録済みフィルター（最新が最下行）から選び、入力欄を置き換える
--   opts.with_text = true : 「フィルター名 + 元の文言」（元の文言に付いているフィルター名は付け替え）
--   opts.with_text = false: フィルター名のみ
-- <CR>（ポップアップ表示中）: with_text なら閉じてそのまま確定、そうでなければ閉じて編集を続ける
-- 文字入力: ポップアップを閉じて編集を続ける（次の <C-k> は再び最新から）
memo_input_with_filters = function(prompt, default, opts)
  opts = opts or {}
  local list = memo_filters_by_recent()
  -- idx: 0 = 未選択、1 = 最新、#list = 最古 / base: <C-k> を押し始めた時点の入力内容
  local st   = { win = nil, idx = 0, last_set = nil, base = '' }

  local function close()
    if st.win and vim.api.nvim_win_is_valid(st.win) then vim.api.nvim_win_close(st.win, true) end
    st.win = nil
  end

  local function show()
    local row  = #list - st.idx + 1
    local name = list[row].name
    if opts.with_text then
      local body = memo_strip_any_filter_prefix(st.base)
      st.last_set = body == '' and (name .. ' ') or (name .. ' ' .. body)
    else
      st.last_set = name
    end
    vim.fn.setcmdline(st.last_set)
    local cr    = opts.with_text and '<CR>=決定' or '<CR>=確定'
    local title = string.format(' Filters (%d/%d)  <C-k>/<C-p>=上(古い) <C-j>/<C-n>=下(新しい) %s ', st.idx, #list, cr)
    if not (st.win and vim.api.nvim_win_is_valid(st.win)) then
      local lines, hls = {}, {}
      for i, flt in ipairs(list) do memo_filter_line(flt, i - 1, lines, hls) end
      st.win = memo_popup_open(memo_popup_buf(lines, hls), #list, title, false)
    else
      vim.api.nvim_win_set_config(st.win, { title = title })
    end
    vim.api.nvim_win_set_cursor(st.win, { row, 0 })
    vim.cmd('redraw')
  end

  -- 手入力でコマンドラインが変わったらポップアップを閉じる（setcmdline による変更は last_set と一致するので無視）
  local au = vim.api.nvim_create_autocmd('CmdlineChanged', {
    callback = function()
      if st.win and vim.fn.getcmdline() ~= st.last_set then
        close()
        st.idx = 0
        vim.cmd('redraw')
      end
    end,
  })

  local function up()
    if #list == 0 then vim.notify('No filters', vim.log.levels.INFO); return end
    if st.idx == 0 then st.base = vim.fn.getcmdline() end
    st.idx = math.min(st.idx + 1, #list)
    show()
  end
  local function down()
    if st.idx <= 1 then return end
    st.idx = st.idx - 1
    show()
  end
  local function feed(key)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'n', false)
  end

  local input = memo_with_cmap({
    ['<C-k>'] = up,
    ['<C-j>'] = down,
    -- <C-p>/<C-n>: ポップアップ表示中だけ上/下。表示中でなければ通常のコマンドライン履歴
    ['<C-p>'] = function() if st.win then up() else feed('<C-p>') end end,
    ['<C-n>'] = function() if st.win then down() else feed('<C-n>') end end,
    ['<CR>'] = function()
      if st.win and not opts.with_text then
        close()
        st.idx = 0
        vim.cmd('redraw')
        return
      end
      close()
      feed('<CR>')
    end,
  }, function() return vim.fn.input(prompt, default) end)

  pcall(vim.api.nvim_del_autocmd, au)
  close()
  -- コマンドラインでは <C-v> などで改行が文字として入ることがある。メモ・フィルター名には不要なので除去する
  return (input:gsub('[\r\n]', ''))
end

-- フィルターを決定する
-- 方式1: カーソル行にメモがあればそのテキストを初期値にして編集（カーソル配下のメモは変更しない）
-- 方式2: カーソル行にメモがなければ空の入力から新規作成
-- 入力中は <C-k>/<C-j> で登録済みフィルターのポップアップ（最新が最下行）から選べる。<CR> で確定 → 編集、もう一度 <CR> で適用
local function memo_filter_set()
  local bufnr = vim.api.nvim_get_current_buf()
  local line0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, memo_ns, { line0, 0 }, { line0, -1 }, {})
  local default = ''
  if #marks > 0 then
    local m = (buf_memos[bufnr] or {})[marks[1][1]]
    if m then default = m.text end
  end
  local input = memo_input_with_filters('Filter: ', default)
  vim.cmd('redraw')
  if input == '' then return end
  memo_filter_activate(input)
end

-- フィルターごとの適用 ON/OFF をポップアップで切り替える
-- 行: 登録済みフィルター（古い順、適用中は ※）+ 最下行「全体」（フィルター適用全体の ON/OFF）
-- 起動直後は最下行。<C-k>/<C-j>（k/j）で移動、<Tab> で切替、<CR>/<Esc>/q で閉じる
local function memo_filter_toggle()
  if #memo_filters == 0 then
    vim.notify('No filters (<leader>mg で作成)', vim.log.levels.INFO)
    return
  end
  local list = memo_filters_by_recent()

  local function title()
    return ' Filter Toggle ' .. (memo_filter_enabled and '[ON]' or '[OFF]') .. '  <C-k>/<C-p>=上(古い) <C-j>/<C-n>=下(新しい) <Tab>=ON/OFF <CR>=閉じる '
  end

  local function render(buf)
    local lines, hls = {}, {}
    for i, flt in ipairs(list) do memo_filter_line(flt, i - 1, lines, hls) end
    table.insert(lines, memo_filter_enabled and ' ◉ 全体: ON' or ' ○ 全体: OFF')
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
    for _, h in ipairs(hls) do vim.api.nvim_buf_add_highlight(buf, -1, h[4], h[1], h[2], h[3]) end
    vim.bo[buf].modifiable = false
  end

  local buf = memo_popup_buf({}, {})
  render(buf)
  local win = memo_popup_open(buf, #list + 1, title(), true)
  vim.api.nvim_win_set_cursor(win, { #list + 1, 0 })

  local function apply()
    memo_filters_save()
    memo_refresh_all_bufs()
    memo_update_airline()
    if vim.api.nvim_win_is_valid(win) then
      local cur = vim.api.nvim_win_get_cursor(win)
      render(buf)
      vim.api.nvim_win_set_config(win, { title = title() })
      vim.api.nvim_win_set_cursor(win, cur)
    end
  end

  local function toggle()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    if row > #list then
      if #memo_active_filters == 0 then
        vim.notify('No active filter (<Tab> でフィルターを ON にする)', vim.log.levels.INFO)
        return
      end
      memo_filter_enabled = not memo_filter_enabled
    else
      local flt = list[row]
      local removed = false
      for i, n in ipairs(memo_active_filters) do
        if n == flt.name then table.remove(memo_active_filters, i); removed = true; break end
      end
      if not removed then
        table.insert(memo_active_filters, flt.name)
        flt.used_at = os.time()  -- 並び順は次回のポップアップから反映（開いている間は固定）
      end
      memo_filter_enabled = #memo_active_filters > 0
    end
    apply()
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    vim.notify(memo_filter_enabled and #memo_active_filters > 0
      and ('Memo filter ON: ' .. table.concat(memo_active_filters, ', '))
      or  'Memo filter OFF')
  end

  local o = { buffer = buf, nowait = true }
  vim.keymap.set('n', '<C-k>', 'k', o)
  vim.keymap.set('n', '<C-j>', 'j', o)
  vim.keymap.set('n', '<C-p>', 'k', o)
  vim.keymap.set('n', '<C-n>', 'j', o)
  vim.keymap.set('n', '<Tab>', toggle, o)
  for _, key in ipairs({ '<CR>', '<Esc>', 'q' }) do vim.keymap.set('n', key, close, o) end
  -- 別ウィンドウへ移ったら閉じる
  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = buf,
    once   = true,
    callback = function() vim.schedule(function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end) end,
  })
end

-- Telescope でフィルター一覧を表示する（<Tab> で適用/未適用をトグル）
local function memo_filter_pick()
  if #memo_filters == 0 then
    vim.notify('No filters (<leader>mg で作成)', vim.log.levels.INFO)
    return
  end
  local square = '██ '           -- カラーピッカーと同じ着色四角表示
  local sq_len = #square

  local function make_title()
    return '📝 Memo Filters ' .. (memo_filter_enabled and '[ON]' or '[OFF]')
      .. '  <Tab>=適用トグル <CR>=閉じる <C-d>=削除'
  end

  -- トグルで表示（※ マーク）を作り直せるよう finder は都度生成する
  local function make_finder()
    return finders.new_table({
      results     = memo_filters,
      entry_maker = function(flt)
        -- グループ色未設定はデフォルトのメモ色（MemoHighlight と同じ）で色アイコンを表示する
        local hex = flt.color or memo_color_load()
        vim.api.nvim_set_hl(0, 'ColorPickerHL_' .. hex:sub(2), { fg = hex })
        -- 適用中のフィルターには ※ を付ける
        local active = vim.tbl_contains(memo_active_filters, flt.name)
        local disp   = square .. flt.name .. (active and '※' or '')
        local hl     = { { { 0, sq_len }, 'ColorPickerHL_' .. hex:sub(2) } }
        return {
          value   = flt,
          display = function() return disp, hl end,
          ordinal = flt.name,
        }
      end,
    })
  end

  pickers.new({}, {
    prompt_title = make_title(),
    finder       = make_finder(),
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      -- 選択行ハイライトを fg なし版に差し替え（着色四角を維持するため）
      vim.schedule(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        if picker and picker.results_win and vim.api.nvim_win_is_valid(picker.results_win) then
          vim.wo[picker.results_win].winhighlight = 'TelescopeSelection:ColorPickerSelection'
        end
      end)
      -- トグル後に ※ マークとタイトルを反映し、カーソルを1行上へ移動する
      local function refresh_picker()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local row = picker:get_selection_row()
        pcall(function() picker.prompt_border:change_title(make_title()) end)
        picker:refresh(make_finder(), { reset_prompt = false })
        vim.defer_fn(function()
          pcall(picker.set_selection, picker, math.max(row - 1, 0))
        end, 30)
      end
      -- <Tab>: カーソル行フィルターの適用/未適用を即時トグルする
      local function toggle_filter()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local name    = sel.value.name
        local removed = false
        for i, n in ipairs(memo_active_filters) do
          if n == name then table.remove(memo_active_filters, i); removed = true; break end
        end
        if not removed then table.insert(memo_active_filters, name) end
        memo_filter_enabled = #memo_active_filters > 0
        memo_filters_save()
        memo_refresh_all_bufs()
        memo_update_airline()
        refresh_picker()
      end
      map_modes(map, '<Tab>', toggle_filter)
      -- <CR>: 閉じる（適用状態は <Tab> で即時反映済み）
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        vim.notify(#memo_active_filters > 0
          and ('Memo filter: ' .. table.concat(memo_active_filters, ', '))
          or  'Memo filter OFF')
      end)
      -- <C-d>: フィルター定義を削除する（メモ本体は変更しない）
      local function delete_filter()
        local sel = action_state.get_selected_entry()
        if not sel then return end
        local picker = action_state.get_current_picker(prompt_bufnr)
        for i, flt in ipairs(memo_filters) do
          if flt.name == sel.value.name then table.remove(memo_filters, i); break end
        end
        for i, name in ipairs(memo_active_filters) do
          if name == sel.value.name then table.remove(memo_active_filters, i); break end
        end
        memo_filters_save()
        memo_refresh_all_bufs()
        memo_update_airline()
        picker:delete_selection(function() vim.notify('Filter deleted') end)
      end
      map_modes(map, '<C-d>', delete_filter)
      return true
    end,
    layout_strategy = 'center',
    layout_config   = { width = 100, height = 30 },
  }):find()
end

vim.keymap.set('n', '<leader>ma', memo_add_or_edit,              { desc = 'Memo add/edit' })
vim.keymap.set('n', '<leader>ms', memo_select_from_list,            { desc = 'Memo select from list' })
vim.keymap.set('n', '<leader>me', function()
  -- 候補ファイルが存在しない場合は空ファイルを作成する
  if vim.fn.filereadable(memo_candidates_path) == 0 then
    local fh = io.open(memo_candidates_path, 'w')
    if fh then fh:close() end
  end
  vim.cmd('botright vsplit ' .. vim.fn.fnameescape(memo_candidates_path))
end, { desc = 'Memo edit candidates file' })
vim.keymap.set('n', '<leader>ml', function() memo_list() end,     { desc = 'Memo list (telescope)' })
vim.keymap.set('n', '<leader>ll', memo_list_current,             { desc = 'Memo list current file' })
vim.keymap.set('n', '<leader>mb', memo_list_buffers,             { desc = 'Memo list buffer memos' })
vim.keymap.set('n', '<leader>mv', memo_list_active,              { desc = 'Memo list active (visible) memos' })
vim.keymap.set('n', '<leader>my', memo_copy_at_cursor,           { desc = 'Memo copy text at cursor' })
vim.keymap.set('n', '<leader>md', memo_delete,                   { desc = 'Memo delete' })
vim.keymap.set('n', '<leader>mc', memo_change_color_at_cursor,   { desc = 'Memo change color at cursor' })
vim.keymap.set('n', '<leader>mf', memo_add_template,             { desc = 'Memo add template (呼び出し調査の起点)' })
vim.keymap.set('n', '<leader>mL', function() memo_list(true) end, { desc = 'Memo list filtered only' })
vim.keymap.set('n', '<leader>mm', memo_list_mru,                 { desc = 'Memo list recently used (MRU)' })
vim.keymap.set('n', '<leader>mr', memo_force_reload,             { desc = 'Memo force reload' })
vim.keymap.set('n', '<leader>mg', memo_filter_set,               { desc = 'Memo filter set (カーソル配下 or 新規入力)' })
vim.keymap.set('n', '<leader>mt', memo_filter_toggle,            { desc = 'Memo filter toggle (ポップアップでフィルターごとに ON/OFF)' })
vim.keymap.set('n', '<leader>mo', memo_filter_pick,              { desc = 'Memo filter list (telescope)' })



-- セッション連携 API（rc/session.lua から呼び出す）
local M = {}

-- セッション保存時: フィルター選択状態をセッション名に紐付けて保存する
function M.session_store(name)
  memo_session_states[name] = {
    active  = vim.deepcopy(memo_active_filters),
    enabled = memo_filter_enabled,
  }
  memo_filters_save()
end

-- セッションロード時: セッション名に紐付くフィルター選択状態を復旧する
-- （バッファのメモロードは defer されるため、先に状態を戻しておけば新規バッファにも反映される）
function M.session_restore(name)
  local st = memo_session_states[name]
  if not st then return end
  memo_active_filters = type(st.active) == 'table' and st.active or {}
  memo_filter_enabled = st.enabled == true
  memo_filters_save()
  memo_refresh_all_bufs()
  memo_update_airline()
end

-- セッションのリネーム・削除に追従して紐付け状態を維持・破棄する
function M.session_rename(old_name, new_name)
  memo_session_states[new_name] = memo_session_states[old_name]
  memo_session_states[old_name] = nil
  memo_filters_save()
end

function M.session_delete(name)
  memo_session_states[name] = nil
  memo_filters_save()
end

return M

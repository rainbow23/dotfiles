-- メモ管理（extmarks ベース）
-- ファイルを変更せず仮想行としてメモを表示し、~/.vim/memos.json に永続化する
-- キーマップ: <leader>ma=追加/編集 <leader>ms=リストから追加 <leader>me=候補編集 <leader>md=削除 <leader>ml=一覧
--            <leader>mg=フィルター決定 <leader>mt=フィルタートグル <leader>mo=フィルター一覧
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
  f:write(json_pretty(data) .. '\n'); f:close()
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

-- 現在行のメモを追加または編集する
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
  local input = vim.fn.input('Memo: ', default_text or '')
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

-- 現在行のメモテキストをクリップボードにコピーする
local function memo_copy_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local line0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  local marks  = vim.api.nvim_buf_get_extmarks(bufnr, memo_ns, { line0, 0 }, { line0, -1 }, {})
  if #marks == 0 then vim.notify('No memo on this line', vim.log.levels.INFO); return end
  local m = (buf_memos[bufnr] or {})[marks[1][1]]
  if not m then return end
  vim.fn.setreg('+', m.text)
  vim.fn.setreg('"', m.text)
  vim.notify('Copied: ' .. m.text)
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
    local header = { '📝  ' .. text, filepath, string.rep('─', 60), '' }
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
        color    = e.color,
      })
    end
    ::continue::
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

  pickers.new({}, {
    prompt_title  = '📝 Memos  <CR>=ジャンプ <C-d>=削除 <C-r>=リネーム',
    results_title = memo_shortcut,
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
              local old_color = (buf_memos[bufnr][m[1]] or {}).color
              vim.api.nvim_buf_del_extmark(bufnr, memo_ns, m[1])
              buf_memos[bufnr][m[1]] = nil
              memo_set_extmark(bufnr, ln - 1, new_text, old_color)
            end
          end
          memo_list()
        end)
      end
      map_modes(map, '<C-r>', rename_memo)
    end),
  }):find()
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
local function memo_list_current()
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
    prompt_title    = '📝 Memos (current file)  <CR>=ジャンプ <C-d>=削除',
    results_title   = memo_shortcut,
    finder          = finders.new_table({
      results     = results,
      entry_maker = function(e)
        return { value = e, display = e.display, ordinal = e.display, filename = e.filepath, lnum = e.line }
      end,
    }),
    sorter          = make_memo_sorter(results),
    previewer       = memo_previewer,
    attach_mappings = make_memo_attach_mappings(nil),
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
    prompt_title  = '📝 Buffer Memos  <CR>=ジャンプ <C-d>=削除',
    results_title = memo_shortcut,
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
end


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
          local input = vim.fn.input('Memo: ', selected_text)
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
        end)
      end)
      return true
    end,
    layout_strategy = 'center',
    layout_config   = { width = 70, height = 20 },
  }):find()
end

-- フィルターを登録して適用する共通処理（未定義なら定義一覧に追加する）
local function memo_filter_activate(name)
  local found
  for _, flt in ipairs(memo_filters) do
    if flt.name == name then found = flt; break end
  end
  if not found then table.insert(memo_filters, { name = name }) end
  memo_active_filters = { name }
  memo_filter_enabled = true
  memo_filters_save()
  memo_refresh_all_bufs()
  vim.notify('Memo filter: ' .. name)
end

-- フィルターを決定する
-- 方式1: カーソル行にメモがあればそのテキストを初期値にして編集（カーソル配下のメモは変更しない）
-- 方式2: カーソル行にメモがなければ空の入力から新規作成
local function memo_filter_set()
  local bufnr = vim.api.nvim_get_current_buf()
  local line0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, memo_ns, { line0, 0 }, { line0, -1 }, {})
  local default = ''
  if #marks > 0 then
    local m = (buf_memos[bufnr] or {})[marks[1][1]]
    if m then default = m.text end
  end
  local input = vim.fn.input('Filter: ', default)
  vim.cmd('redraw')
  if input == '' then return end
  memo_filter_activate(input)
end

-- フィルター適用状態をトグルする（OFF なら全メモ表示）
local function memo_filter_toggle()
  if #memo_active_filters == 0 then
    vim.notify('No active filter (<leader>mg で作成)', vim.log.levels.INFO)
    return
  end
  memo_filter_enabled = not memo_filter_enabled
  memo_filters_save()
  memo_refresh_all_bufs()
  vim.notify(memo_filter_enabled
    and ('Memo filter ON: ' .. table.concat(memo_active_filters, ', '))
    or  'Memo filter OFF')
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
vim.keymap.set('n', '<leader>mb', memo_list_buffers,             { desc = 'Memo list buffer memos' })
vim.keymap.set('n', '<leader>my', memo_copy_at_cursor,           { desc = 'Memo copy text at cursor' })
vim.keymap.set('n', '<leader>md', memo_delete,                   { desc = 'Memo delete' })
vim.keymap.set('n', '<leader>mc', memo_change_color_at_cursor,   { desc = 'Memo change color at cursor' })
vim.keymap.set('n', '<leader>mf', memo_add_template,             { desc = 'Memo add template (呼び出し調査の起点)' })
vim.keymap.set('n', '<leader>ml', memo_list,                     { desc = 'Memo list (telescope)' })
vim.keymap.set('n', '<leader>ll', memo_list_current,             { desc = 'Memo list current file' })
vim.keymap.set('n', '<leader>mr', memo_force_reload,             { desc = 'Memo force reload' })
vim.keymap.set('n', '<leader>mg', memo_filter_set,               { desc = 'Memo filter set (カーソル配下 or 新規入力)' })
vim.keymap.set('n', '<leader>mt', memo_filter_toggle,            { desc = 'Memo filter toggle' })
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

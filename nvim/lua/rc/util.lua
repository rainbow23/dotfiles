-- telescope picker 共通ユーティリティ
local M = {}

-- telescope picker のレイアウトプリセット
-- plugins/telescope.lua の defaults（layout_config / cycle_layout_list）に反映され、
-- 全 picker 共通の初期レイアウトと <C-l> レイアウト切替として機能する
M.telescope_layout_presets = {
  { layout_strategy = 'horizontal', layout_config = { height = 0.9, width = 0.9, preview_width  = 0.4, prompt_position = 'bottom' } },
  { layout_strategy = 'vertical',   layout_config = { height = 0.9, width = 0.9, preview_height = 0.4, prompt_position = 'bottom', preview_cutoff = 1 } },
}

-- i/n 両モードに同じキーマップを登録するユーティリティ
function M.map_modes(map, key, fn)
  map('i', key, fn)
  map('n', key, fn)
end

-- vsplit キーは環境によって異なる（GitBash/Windows: <M-v>、mac/unix: <C-v>）
M.vsplit_key = vim.fn.has('win32') == 1 and '<M-v>' or '<C-v>'

-- telescope picker 共通ショートカット文字列（results_title に表示）
M.shortcut_common = '<C-f>=Preview <C-l>=レイアウト切替 <Tab>=複数選択 <C-t>=新規タブ ' .. M.vsplit_key .. '=vsplit <C-h>=hsplit'

-- entry から開くファイルの絶対パスを求める
-- telescope の entry は picker によって path / filename / value のどれかを持つ
local function entry_path(entry, cwd)
  local path = entry.path or entry.filename or entry.value
  if type(path) ~= 'string' or path == '' then return nil end
  -- 相対パスの entry（cwd 基準）は picker の cwd を前置して絶対パス化する
  local is_abs = path:match('^[/\\]') or path:match('^%a:[/\\]')
  if not is_abs and cwd and cwd ~= '' then
    path = cwd .. '/' .. path
  end
  return path
end

-- <Tab> で複数選択されたエントリを cmd（tabedit/vsplit/split）ですべて開く
-- 選択が 1 件以下なら telescope 標準アクション（fallback）に委譲し、従来の挙動を保つ
function M.open_multi_or(prompt_bufnr, cmd, fallback)
  local actions      = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local picker       = action_state.get_current_picker(prompt_bufnr)
  local entries      = picker and picker:get_multi_selection() or {}
  if #entries <= 1 then return fallback(prompt_bufnr) end
  local cwd = picker.cwd
  actions.close(prompt_bufnr)
  vim.schedule(function()
    for _, entry in ipairs(entries) do
      local path = entry_path(entry, cwd)
      if path then
        vim.cmd(cmd .. ' ' .. vim.fn.fnameescape(path))
        if entry.lnum then
          local lnum = math.max(1, math.min(entry.lnum, vim.api.nvim_buf_line_count(0)))
          vim.api.nvim_win_set_cursor(0, { lnum, math.max(0, (entry.col or 1) - 1) })
          vim.cmd('normal! zz')
        end
      end
    end
  end)
end

-- telescope picker 共通の attach_mappings ファクトリ
-- preview_default_on: false の場合、起動時にプレビューを非表示にする
-- extra_mappings: picker 固有の追加キーマップ function(prompt_bufnr, map)
function M.make_attach_mappings(preview_default_on, extra_mappings)
  return function(prompt_bufnr, map)
    local actions        = require('telescope.actions')
    local layout_actions = require('telescope.actions.layout')
    if not preview_default_on then
      vim.schedule(function() layout_actions.toggle_preview(prompt_bufnr) end)
    end
    -- <Tab>: multi-select トグル（トグル後は次の候補へ移動）
    M.map_modes(map, '<Tab>', function(b)
      actions.toggle_selection(b)
      actions.move_selection_worse(b)
    end)
    -- 開く系は複数選択に対応（未選択時は telescope 標準アクションにフォールバック）
    M.map_modes(map, '<C-t>',      function(b) M.open_multi_or(b, 'tabedit', actions.select_tab) end)
    M.map_modes(map, M.vsplit_key, function(b) M.open_multi_or(b, 'vsplit',  actions.select_vertical) end)
    M.map_modes(map, '<C-h>',      function(b) M.open_multi_or(b, 'split',   actions.select_horizontal) end)
    M.map_modes(map, '<C-f>',      layout_actions.toggle_preview)
    if extra_mappings then extra_mappings(prompt_bufnr, map) end
    return true
  end
end

return M

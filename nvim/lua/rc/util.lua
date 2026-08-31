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
M.shortcut_common = '<C-f>=Preview <C-l>=レイアウト切替 <C-t>=新規タブ ' .. M.vsplit_key .. '=vsplit <C-h>=hsplit'

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
    M.map_modes(map, M.vsplit_key, actions.select_vertical)
    M.map_modes(map, '<C-h>',      actions.select_horizontal)
    M.map_modes(map, '<C-f>',      layout_actions.toggle_preview)
    if extra_mappings then extra_mappings(prompt_bufnr, map) end
    return true
  end
end

return M

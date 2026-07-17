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

return M

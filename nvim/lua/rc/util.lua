-- telescope picker 共通ユーティリティ（search / session / memo / bookmarks で共用）
local M = {}

-- telescope picker のレイアウトプリセット
-- <C-l> トグルで { layout_strategy, layout_config } の順に循環する
M.telescope_layout_presets = {
  { layout_strategy = 'horizontal', layout_config = { height = 0.9, width = 0.9, preview_width  = 0.4, prompt_position = 'bottom' } },
  { layout_strategy = 'vertical',   layout_config = { height = 0.9, width = 0.9, preview_height = 0.4, prompt_position = 'bottom', preview_cutoff = 1 } },
}

-- telescope picker 内で <C-l> レイアウト切替を行う関数を生成する
function M.make_layout_toggle(prompt_bufnr, layouts)
  layouts = layouts or M.telescope_layout_presets
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

-- i/n 両モードに同じキーマップを登録するユーティリティ
function M.map_modes(map, key, fn)
  map('i', key, fn)
  map('n', key, fn)
end

return M

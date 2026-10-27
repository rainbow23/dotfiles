-- キーマップ一覧（telescope）。選択した項目の処理をそのまま実行する
-- 各機能モジュールが M.register(group, items) で登録し、M.open(group) で一覧を開く
-- items: { { lhs = '<leader>ma', desc = '説明', fn = function() end }, ... }（登録順に表示）
local conf         = require('telescope.config').values
local finders      = require('telescope.finders')
local pickers      = require('telescope.pickers')
local actions      = require('telescope.actions')
local action_state = require('telescope.actions.state')

local M = {}

local groups = {}  -- { [group] = items }

-- items を登録し、同時に normal モードのキーマップも設定する
function M.register(group, items)
  groups[group] = items
  for _, it in ipairs(items) do
    vim.keymap.set('n', it.lhs, it.fn, { desc = it.desc })
  end
end

function M.open(group)
  local items = groups[group]
  if not items or #items == 0 then
    vim.notify('No keymaps: ' .. tostring(group), vim.log.levels.INFO)
    return
  end
  -- キー列の幅を揃える（表示は <leader> のまま）
  local width = 0
  for _, it in ipairs(items) do width = math.max(width, vim.fn.strdisplaywidth(it.lhs)) end

  -- 登録順を保ったまま絞り込む（スコアが低いほどプロンプト寄り = 先頭の項目が選択位置に来る）
  local fzy = require('telescope.algos.fzy')
  local sorter = require('telescope.sorters').Sorter:new({
    discard = false,
    scoring_function = function(_, prompt, line, entry)
      if prompt ~= '' and not fzy.has_match(prompt:lower(), (line or ''):lower()) then return -1 end
      return entry.index
    end,
  })

  pickers.new({}, {
    prompt_title = '⌨ Keymaps [' .. group .. ']  <CR>=実行',
    finder = finders.new_table({
      results     = items,
      entry_maker = function(it)
        local pad = string.rep(' ', width - vim.fn.strdisplaywidth(it.lhs))
        local display = it.lhs .. pad .. '  ' .. it.desc
        return { value = it, display = display, ordinal = display }
      end,
    }),
    sorter = sorter,
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local sel = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        -- 閉じて元のウィンドウ（カーソル位置）に戻ってから実行する
        if sel then vim.schedule(sel.value.fn) end
      end)
      return true
    end,
    layout_strategy = 'center',
    layout_config   = { width = 0.6, height = 0.6 },
  }):find()
end

return M

return {
  {
    'nvim-telescope/telescope.nvim',
    lazy = false,
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local actions        = require('telescope.actions')
      local layout_actions = require('telescope.actions.layout')
      local presets        = require('rc.util').telescope_layout_presets
      require('telescope').setup({
        defaults = {
          -- 全 picker 共通の初期レイアウト（プリセット[1]）
          -- layout_config は strategy 名前空間で持たせ、<C-l> の切替後も各プリセットが適用される
          layout_strategy = presets[1].layout_strategy,
          layout_config = {
            [presets[1].layout_strategy] = presets[1].layout_config,
            [presets[2].layout_strategy] = presets[2].layout_config,
          },
          -- <C-l>（cycle_layout_next）で循環するレイアウト
          -- 初期状態がプリセット[1]のため、初回トグルで[2]へ切り替わるよう[2]を先頭にする
          -- 注意: table 形式で渡すと previewer なしの picker（セッション一覧など）で
          -- all_previewers が nil のまま index されてエラーになるため string 形式で指定する
          cycle_layout_list = { presets[2].layout_strategy, presets[1].layout_strategy },
          mappings = {
            i = {
              -- Esc でウィンドウを閉じる（_vimrc の noremap <ESC> による上書きを回避）
              ['<esc>'] = actions.close,
              ['<C-l>'] = layout_actions.cycle_layout_next,
            },
            n = {
              ['<esc>'] = actions.close,
              ['<C-l>'] = layout_actions.cycle_layout_next,
            },
          },
        },
      })
    end,
  },
}

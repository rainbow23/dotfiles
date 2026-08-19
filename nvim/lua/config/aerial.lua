-- 画面右側に関数・変数のアウトラインを表示する（プラグイン定義は plugins/aerial.lua）
require('aerial').setup({
  -- LSP を優先し、無い場合は treesitter/markdown/man へフォールバック
  backends = { 'lsp', 'treesitter', 'markdown', 'man' },

  layout = {
    default_direction = 'right',  -- 常に画面右側へ開く
    placement = 'edge',           -- 画面端に全高で配置（NERDTree と対になる形）
    min_width = 30,
    max_width = { 50, 0.3 },
  },

  -- カーソルのあるバッファのシンボルを常に表示する
  attach_mode = 'global',
  -- 選択してもアウトラインは開いたままにする
  close_on_select = false,
  -- 階層を罫線で表示する
  show_guides = true,

  -- 表示するシンボル種別（関数だけでなく変数・定数・フィールドも出す）
  filter_kind = {
    'Class', 'Constructor', 'Enum', 'Function', 'Interface', 'Module',
    'Method', 'Struct', 'Variable', 'Constant', 'Field', 'Property',
  },

  -- カーソル行に対応するシンボルを強調する
  highlight_on_hover = true,
})

-- <Leader>o でアウトラインをトグル、<Leader>O で開いてフォーカス
vim.keymap.set('n', '<Leader>o', '<Cmd>AerialToggle<CR>',       { silent = true, desc = 'アウトライン切替' })
vim.keymap.set('n', '<Leader>O', '<Cmd>AerialToggle! right<CR>', { silent = true, desc = 'アウトラインを開いて移動' })

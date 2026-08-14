-- telescope 本体（読み込みのみ。設定は config/telescope.lua）
return {
  {
    'nvim-telescope/telescope.nvim',
    lazy = false,
    dependencies = { 'nvim-lua/plenary.nvim' },
  },
}

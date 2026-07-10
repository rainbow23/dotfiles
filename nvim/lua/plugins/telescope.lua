return {
  {
    'nvim-telescope/telescope.nvim',
    lazy = false,
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      -- Esc でウィンドウを閉じる（_vimrc の noremap <ESC> による上書きを回避）
      require('telescope').setup({
        defaults = {
          mappings = {
            i = { ['<esc>'] = require('telescope.actions').close },
            n = { ['<esc>'] = require('telescope.actions').close },
          },
        },
      })
    end,
  },
}

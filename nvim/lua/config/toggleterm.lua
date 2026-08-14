-- toggleterm 設定（プラグインロード後に require すること）
require('toggleterm').setup()
local Terminal = require('toggleterm.terminal').Terminal
local tig = Terminal:new({
  cmd = 'tig',
  direction = 'float',
  float_opts = { border = 'curved' },
  on_open = function() vim.cmd('startinsert!') end,
})
vim.keymap.set('n', '<leader>tig', function() tig:toggle() end, { desc = 'tig float' })

-- smart-splits.nvim: Neovim split ↔ ターミナルペインのシームレス移動
-- tmux / zellij を自動検出するため multiplexer_integration は指定しない
require('smart-splits').setup({
  -- Zellij で端のペインから次/前のタブへ移動する
  zellij_move_focus_or_tab = true,
})

vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left,  { desc = 'Move left (split/pane)' })
vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down,  { desc = 'Move down (split/pane)' })
vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up,    { desc = 'Move up (split/pane)' })
vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right, { desc = 'Move right (split/pane)' })

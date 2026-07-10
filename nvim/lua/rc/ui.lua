-- UI ハイライト（colorscheme 適用後に再定義）
local function restore_ui_hl()
  vim.api.nvim_set_hl(0, 'TelescopeSelection', { bg = '#87CEEB', fg = '#000000', bold = true })
  vim.api.nvim_set_hl(0, 'TabLineSel',         { bg = '#87CEEB', fg = '#000000', bold = true })
  -- NormalFloat を Normal にリンク: iTerm 半透明環境で float が白くなるのを防ぐ
  vim.api.nvim_set_hl(0, 'NormalFloat',  { link = 'Normal' })
  -- float window の枠線を白色にする
  vim.api.nvim_set_hl(0, 'FloatBorder',  { fg = '#FFFFFF' })
  -- zoom backdrop: tmux popup 風の灰色背景
  vim.api.nvim_set_hl(0, 'ZoomBackdrop', { bg = '#3a3a3a', fg = '#3a3a3a' })
  -- カラーピッカー選択行: fg 指定なしで着色テキストを維持する
  vim.api.nvim_set_hl(0, 'ColorPickerSelection', { bg = '#555555', bold = true })
end
vim.api.nvim_create_autocmd({ 'VimEnter', 'ColorScheme' }, { callback = restore_ui_hl })

-- タブラインにファイル名のみ表示する
function _G.MyTabLine()
  local s = ''
  for i = 1, vim.fn.tabpagenr('$') do
    s = s .. (i == vim.fn.tabpagenr() and '%#TabLineSel#' or '%#TabLine#')
    s = s .. '%' .. i .. 'T'
    local bufnr = vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]
    local name  = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t')
    if name == '' then name = '[No Name]' end
    s = s .. ' ' .. name .. ' '
  end
  return s .. '%#TabLineFill#%T'
end
vim.opt.tabline = '%!v:lua.MyTabLine()'

-- ターミナルリサイズ時にウィンドウ分割を均等化する（w= 相当）
vim.api.nvim_create_autocmd('VimResized', {
  callback = function() vim.cmd('wincmd =') end,
})

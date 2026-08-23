-- UI ハイライト（colorscheme 適用後に再定義）
local function restore_ui_hl()
  vim.api.nvim_set_hl(0, 'TelescopeSelection', { bg = '#87CEEB', fg = '#000000', bold = true })
  vim.api.nvim_set_hl(0, 'TabLineSel',         { bg = '#87CEEB', fg = '#000000', bold = true })
  -- 非活性タブ: 文字色は活性時と同じ黒。背景を明るい灰にして可読性を確保する
  vim.api.nvim_set_hl(0, 'TabLine',            { bg = '#d0d0d0', fg = '#000000' })
  -- NormalFloat を Normal にリンク: iTerm 半透明環境で float が白くなるのを防ぐ
  vim.api.nvim_set_hl(0, 'NormalFloat',  { link = 'Normal' })
  -- float window の枠線を白色にする
  vim.api.nvim_set_hl(0, 'FloatBorder',  { fg = '#FFFFFF' })
  -- zoom backdrop: tmux popup 風の灰色背景
  vim.api.nvim_set_hl(0, 'ZoomBackdrop', { bg = '#3a3a3a', fg = '#3a3a3a' })
  -- カラーピッカー選択行: fg 指定なしで着色テキストを維持する
  vim.api.nvim_set_hl(0, 'ColorPickerSelection', { bg = '#555555', bold = true })
  -- render-markdown: 見出し・コードブロックを白背景・黒文字にする
  for i = 1, 6 do
    vim.api.nvim_set_hl(0, 'RenderMarkdownH' .. i .. 'Bg', { bg = '#FFFFFF', fg = '#000000' })
  end
  vim.api.nvim_set_hl(0, 'RenderMarkdownCode',       { bg = '#FFFFFF', fg = '#000000' })
  -- インラインコード（`backtick`）のハイライトを除去
  vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInline', {})
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

-- InsertLeave（Esc）時に英語 IME へ自動切替（im-select が必要）
-- macOS: brew install im-select
-- Windows/GitBash: https://github.com/daipeihust/im-select から im-select.exe を PATH に配置
if vim.fn.executable('im-select') == 1 then
  local im_en = vim.fn.has('mac') == 1 and 'com.apple.keylayout.ABC' or '1033'
  vim.api.nvim_create_autocmd('InsertLeave', {
    callback = function() vim.fn.system('im-select ' .. im_en) end,
  })
end

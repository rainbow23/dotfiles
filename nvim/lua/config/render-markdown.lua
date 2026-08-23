-- Markdown バッファ内レンダリング（プラグイン定義は plugins/render-markdown.lua）
require('render-markdown').setup({
  -- 見出し: 色は restore_ui_hl（rc/ui.lua）で RenderMarkdownH1Bg〜H6Bg を上書き
  heading = {
    enabled = true,
    sign = false,
  },
  -- コードブロック: 色は restore_ui_hl（rc/ui.lua）で RenderMarkdownCode を上書き
  code = {
    enabled = true,
    sign = false,
    style = 'full',
  },
  -- インラインコード（`backtick`）のハイライトを無効化
  inline_code = {
    enabled = false,
  },
  -- チェックボックスをアイコン化する
  checkbox = {
    enabled = true,
  },
})

-- <Leader>m でレンダリングのオン/オフをトグル
vim.keymap.set('n', '<Leader>m', '<Cmd>RenderMarkdown toggle<CR>', { silent = true, desc = 'Markdown レンダリング切替' })

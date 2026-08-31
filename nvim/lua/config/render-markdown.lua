-- Markdown バッファ内レンダリング（プラグイン定義は plugins/render-markdown.lua）
require('render-markdown').setup({
  heading = {
    enabled = true,
    sign = false,
    backgrounds = {},  -- 見出し背景色を無効化
    -- 見出しを bold のみ（色なし）: RenderMarkdownHeading は rc/ui.lua で定義
    foregrounds = { 'RenderMarkdownHeading', 'RenderMarkdownHeading', 'RenderMarkdownHeading',
                    'RenderMarkdownHeading', 'RenderMarkdownHeading', 'RenderMarkdownHeading' },
  },
  code = {
    enabled = true,
    sign = false,
    style = 'full',
    highlight = '',           -- コードブロック背景色を無効化
    highlight_language = '',  -- 言語ラベルのハイライトを無効化
  },
  inline_code = {
    enabled = true,
    highlight = '',  -- インラインコードのハイライトを無効化
  },
  -- チェックボックスをアイコン化する
  checkbox = {
    enabled = true,
  },
})

-- <Leader>m でレンダリングのオン/オフをトグル
vim.keymap.set('n', '<Leader>rm', '<Cmd>RenderMarkdown toggle<CR>', { silent = true, desc = 'Markdown レンダリング切替' })

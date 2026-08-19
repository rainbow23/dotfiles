-- 関数・変数のアウトライン表示（設定は config/aerial.lua）
-- LSP のドキュメントシンボルを使うため plugins/lsp.lua の後に読み込む
return {
  {
    'stevearc/aerial.nvim',
    branch = 'nvim-0.11',  -- master は Neovim 0.12 以降が必要
    lazy = false,
    dependencies = { 'neovim/nvim-lspconfig' },
  },
}

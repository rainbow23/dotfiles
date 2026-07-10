-- LSP / Completion のプラグイン定義（セットアップは rc/lsp.lua）
return {
  { 'williamboman/mason.nvim',           lazy = false },
  { 'williamboman/mason-lspconfig.nvim', lazy = false, dependencies = { 'williamboman/mason.nvim' } },
  { 'neovim/nvim-lspconfig',             lazy = false },
  { 'hrsh7th/nvim-cmp',                  lazy = false },
  { 'hrsh7th/cmp-nvim-lsp',             lazy = false },
  { 'hrsh7th/cmp-buffer',               lazy = false },
  { 'hrsh7th/cmp-path',                 lazy = false },
  { 'L3MON4D3/LuaSnip',                 lazy = false, build = 'make install_jsregexp' },
  { 'saadparwaiz1/cmp_luasnip',         lazy = false },
  { 'mfussenegger/nvim-jdtls',          lazy = false },
}

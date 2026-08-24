-- LSP サーバー定義（rc/lsp.lua と tools/callgraph.lua で共用）
-- 通常起動と headless 起動（nvim -l）の双方から同じサーバー構成を再現するために切り出している
local M = {}

-- 常時有効化するサーバー
M.names = { 'kotlin_language_server', 'ts_ls', 'sqlls', 'vimls', 'bashls', 'lua_ls' }

-- サーバー個別設定（vim.lsp.config に渡す）
M.configs = {
  -- lua_ls（Neovim API を認識させる追加設定）
  lua_ls = {
    settings = {
      Lua = {
        runtime     = { version = 'LuaJIT' },
        diagnostics = { globals = { 'vim' } },
        workspace   = { library = vim.api.nvim_get_runtime_file('', true), checkThirdParty = false },
        telemetry   = { enable = false },
      },
    },
  },
  -- Swift: Xcode 同梱の sourcekit-lsp
  sourcekit = {
    filetypes = { 'swift' },
  },
}

-- 実行ファイルが存在する場合のみ有効化するサーバーを返す
-- 未導入マシンで起動エラーが出るのを避けるため executable() で判定する
function M.optional_names()
  local names = {}
  -- C#（.NET for Android）: Roslyn Language Server（導入手順は docs/dotnet-android-lsp.md）
  if vim.fn.executable('roslyn-language-server') == 1
    or vim.fn.executable('Microsoft.CodeAnalysis.LanguageServer') == 1 then
    table.insert(names, 'roslyn_ls')
  end
  if vim.fn.executable('sourcekit-lsp') == 1 then
    table.insert(names, 'sourcekit')
  end
  return names
end

-- サーバー設定を登録して有効化する
-- capabilities: nvim-cmp 併用時のみ渡す（headless では nil）
function M.enable(capabilities)
  if capabilities then
    vim.lsp.config('*', { capabilities = capabilities })
  end
  local optional = M.optional_names()
  for _, name in ipairs(optional) do
    if M.configs[name] then vim.lsp.config(name, M.configs[name]) end
  end
  vim.lsp.config('lua_ls', M.configs.lua_ls)
  vim.lsp.enable(M.names)
  for _, name in ipairs(optional) do vim.lsp.enable(name) end
end

-- headless（nvim -l）用のセットアップ
-- -l 起動では個人設定も lazy.nvim も読み込まれないため、rtp と PATH を手動で組み立てる
function M.setup_headless()
  local data = vim.fn.stdpath('data')
  vim.opt.rtp:append(data .. '/lazy/nvim-lspconfig')
  -- mason 導入のサーバー実行ファイルに PATH を通す
  local sep = vim.fn.has('win32') == 1 and ';' or ':'
  vim.env.PATH = data .. '/mason/bin' .. sep .. (vim.env.PATH or '')
  -- 別インスタンスで開いているファイルを読み込むためスワップを無効化する
  vim.opt.swapfile = false
  M.enable(nil)
end

return M

-- ① lazy.nvim bootstrap
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ② leader を先に設定（lazy.nvim のキーマップ定義より前に必要）
vim.g.mapleader = ' '

-- ③ プラグイン定義（lua/plugins/*.lua を自動読込）
require('lazy').setup('plugins')

-- ④ VimScript 設定を source（プラグインロード後）
vim.cmd('source ' .. vim.fn.expand('~/dotfiles/_vimrc'))

-- ⑤ nvim 向け上書き設定
-- autochdir を無効化: bookmarks.nvim が getcwd() を project_root として使うため
-- autochdir が有効だとファイルごとに project_root が変わり複数ファイルのブックマークが表示されない
vim.opt.autochdir = false

-- ⑥ 機能モジュール（lua/rc/）
require('rc.search')   -- telescope 版 FileSearch/GrepSearch/BLines など
require('rc.session')  -- セッション管理
require('rc.memo')     -- extmarks ベースのメモ機能
require('rc.zoom')     -- float window による疑似最大化（,, でトグル）
require('rc.ui')       -- highlight 復元・tabline・リサイズ時の均等化
require('rc.lsp')      -- LSP / 補完設定

-- 起動時に stale な ShaDa tmp ファイルを削除する
-- Windows/GitBash 環境でクラッシュや複数インスタンス起動後に tmp ファイルが残留し
-- "cannot write ShaDa file!" エラーが出る問題への対処
-- 5秒以上前の tmp のみ削除することで、別インスタンスが書き込み中の tmp を誤削除しない
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    local shada_dir = vim.fn.stdpath('data') .. '/shada'
    for _, f in ipairs(vim.fn.glob(shada_dir .. '/main.shada.tmp*', false, true)) do
      local stat = vim.loop.fs_stat(f)
      if stat and (os.time() - stat.mtime.sec) > 5 then
        vim.fn.delete(f)
      end
    end
  end,
})

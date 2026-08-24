-- Windows(GitBash) 固有の起動時設定
-- bookmarks.nvim が依存する sqlite.lua 用。プラグインロード前に設定する必要がある。
if vim.fn.has('win32') == 1 then
  vim.g.sqlite_clib_path = vim.fn.expand('~/myTool/sqlite/sqlite3.dll')
end

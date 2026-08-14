-- bookmarks.nvim（読み込みのみ。設定は config/bookmarks.lua）
return {
  {
    'heilgar/bookmarks.nvim',
    lazy = false,
    dependencies = {
      'kkharji/sqlite.lua',
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
    },
    -- モンキーパッチはプラグインのインストール後・ロード前に適用する必要があるため init で行う
    -- （設定値ではなく、on-disk のプラグインファイルを書き換えるロード順依存の処理）
    init = function()
      require('rc.patches.bookmarks')
    end,
  },
}

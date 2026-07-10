-- bookmarks.nvim へのモンキーパッチ
-- storage.lua の初期スキーマに branch/list が欠けているバグへのワークアラウンド
-- build はインストール時のみ実行されるため init（毎起動・プラグインロード前）で適用する
-- https://github.com/heilgar/bookmarks.nvim/issues/12
local plugin_dir = vim.fn.stdpath('data') .. '/lazy/bookmarks.nvim'
local path = plugin_dir .. '/lua/bookmarks/storage.lua'
local f = io.open(path, 'r')
if not f then return end
local content = f:read('*a')
f:close()
if not content:find('branch%s*=%s*"text"') then
  content = content:gsub(
    '(project_root%s*=%s*"text",)',
    '%1\n                branch       = "text",\n                list         = "text",'
  )
  local fw = io.open(path, 'w')
  if fw then
    fw:write(content)
    fw:close()
  end
end
-- パッチ済みファイルを git の変更検知から除外（lazy.nvim の sync エラーを防ぐ）
vim.fn.system({'git', '-C', plugin_dir, 'update-index', '--assume-unchanged', 'lua/bookmarks/storage.lua'})

-- navigation.lua パッチ: project_root を getcwd() から git root に統一
local nav_path = plugin_dir .. '/lua/bookmarks/navigation.lua'
local fnav = io.open(nav_path, 'r')
if fnav then
  local nav_src = fnav:read('*a')
  fnav:close()
  if not nav_src:find('git rev%-parse') then
    nav_src = nav_src:gsub(
      'local project_root = vim%.fn%.getcwd%(%)',
      function()
        return "local _g = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\\n', '')\n    local project_root = (_g ~= '' and not _g:find('fatal')) and _g or vim.fn.getcwd()"
      end
    )
    local fnav_w = io.open(nav_path, 'w')
    if fnav_w then fnav_w:write(nav_src) fnav_w:close() end
  end
  vim.fn.system({'git', '-C', plugin_dir, 'update-index', '--assume-unchanged', 'lua/bookmarks/navigation.lua'})
end

-- telescope extension パッチ: 一覧表示の project_root を git root に統一
local ext_path = plugin_dir .. '/lua/telescope/_extensions/bookmarks.lua'
local fext = io.open(ext_path, 'r')
if fext then
  local ext_src = fext:read('*a')
  fext:close()
  local changed = false
  if not ext_src:find('git rev%-parse.*show%-toplevel.*getcwd') then
    ext_src = ext_src:gsub(
      'storage%.get_bookmarks%(vim%.fn%.getcwd%(%),',
      function()
        return "storage.get_bookmarks((function() local g = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\\n','') return (g ~= '' and not g:find('fatal')) and g or vim.fn.getcwd() end)(),"
      end
    )
    changed = true
  end
  -- format_bookmark パッチ: ファイルパスを git root 基準の相対パスで表示
  if not ext_src:find('local _gr = vim%.fn%.system') then
    ext_src = ext_src:gsub(
      'local rel_path = vim%.fn%.fnamemodify%(bookmark%.filename, ":%."%)' ,
      function()
        return "local _gr = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\\n','')\n    local _fn = bookmark.filename:gsub('\\\\', '/')\n    local _grn = _gr:gsub('\\\\', '/')\n    local rel_path = (_grn ~= '' and not _grn:find('fatal') and _fn:find(_grn, 1, true) == 1)\n        and _fn:sub(#_grn + 2)\n        or vim.fn.fnamemodify(bookmark.filename, ':.')"
      end
    )
    changed = true
  end
  if changed then
    local fext_w = io.open(ext_path, 'w')
    if fext_w then fext_w:write(ext_src) fext_w:close() end
  end
  vim.fn.system({'git', '-C', plugin_dir, 'update-index', '--assume-unchanged', 'lua/telescope/_extensions/bookmarks.lua'})
end

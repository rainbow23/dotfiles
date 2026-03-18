# nvim: telescope 統合対応

## 概要

bookmarks.nvim の telescope 利用、および fzf#vim グレップコマンドの telescope 置き換えに伴う
不具合修正・機能改善をまとめた資料。

---

## 修正1: telescope 画面を Esc で閉じられない問題

| | 内容 |
|---|---|
| **原因** | `_vimrc` に `noremap <ESC> <C-\><C-n>` が設定されており、nvim 全体で Esc キーが上書きされていた。telescope の normal モードで Esc を押しても「ウィンドウを閉じる」アクションではなく `<C-\><C-n>` が実行されてしまう |
| **対策** | `telescope.setup()` の `defaults.mappings` で insert/normal 両モードの `<Esc>` に明示的に `telescope.actions.close` を設定し、グローバルの noremap より優先させる |

**追加コード (`nvim/init.lua` bookmarks.nvim config 内):**
```lua
require('telescope').setup({
  defaults = {
    mappings = {
      i = { ['<esc>'] = require('telescope.actions').close },
      n = { ['<esc>'] = require('telescope.actions').close },
    },
  },
})
```

---

## 修正2: ブックマーク追加行がハイライトされない問題

| | 内容 |
|---|---|
| **原因** | 処理順序の問題。bookmarks.nvim の `config` で `BookmarkHighlight` が定義された後、`_vimrc` が source され `colorscheme torte` が適用される。colorscheme 適用時にすべてのハイライトグループがクリアされ `BookmarkHighlight` が消える。bookmarks.nvim の `ColorScheme` autocmd はバッファ再描画のみ行い、ハイライトグループの再定義はしないため視覚的に何も表示されなくなる |
| **対策** | `VimEnter`（`_vimrc` source 完了後に一度実行）と `ColorScheme`（colorscheme 変更のたびに実行）イベントで `BookmarkHighlight` / `BookmarkSignHighlight` を再定義し、`refresh_all_buffers()` でバッファへの適用も再実行する |

**起動時の処理フロー:**
```
nvim/init.lua
  └─ lazy.setup() → bookmarks.nvim config
       └─ Decorations.setup() → BookmarkHighlight 定義
  └─ vim.cmd('source _vimrc')
       └─ colorscheme torte → BookmarkHighlight が消える  ←問題箇所
  └─ VimEnter autocmd 発火
       └─ restore_bookmark_hl() → BookmarkHighlight 再定義 + refresh_all_buffers()
```

**追加コード (`nvim/init.lua` bookmarks.nvim config 内):**
```lua
local function restore_bookmark_hl()
  vim.api.nvim_set_hl(0, 'BookmarkHighlight',     { bg = '#594d3e', bold = true })
  vim.api.nvim_set_hl(0, 'BookmarkSignHighlight', { fg = '#FFE5B4', bold = true })
  require('bookmarks.autocmds').refresh_all_buffers()
end
vim.api.nvim_create_autocmd({ 'VimEnter', 'ColorScheme' }, {
  callback = restore_bookmark_hl,
})
```

---

## 修正3: Search / SearchFromCurrDir を fzf#vim から telescope に置き換え

### 変更の背景

`[fzf]s` / `[fzf]S` キーマップで呼び出す `:Search` / `:SearchFromCurrDir` コマンドを
fzf#vim#grep ベースから telescope の live_grep ベースに置き換え。

### fzf 版との対応関係

| fzf 版オプション | telescope 版での扱い |
|---|---|
| `--column` | telescope 内部で自動付与 |
| `--line-number` | telescope 内部で自動付与 |
| `--no-heading` | telescope 内部で自動付与 |
| `--color=always` | telescope 内部で制御（追加不可）|
| `--hidden` | `additional_args` に明示追加 |
| `--smart-case` | `additional_args` に明示追加 |
| `-g !.git/` | `additional_args` に明示追加（Search のみ）|

### nvim/vim の切り替え

`_vimrc` の fzf 版コマンドを `if !has('nvim')` で囲み、vim では引き続き fzf を使用。
nvim では `nvim/init.lua` に定義した telescope 版を使用する。

```vim
" _vimrc
if !has('nvim')
  command! -bang -nargs=* Search ...       " fzf 版（vim 用）
  command! -bang -nargs=* SearchFromCurrDir ...
endif
```

### telescope 内部モジュールの役割

カスタムピッカーを実装するために telescope の内部モジュールを直接利用している。
各モジュールの役割は以下のとおり。

#### `require('telescope.config').values`

telescope のグローバル設定値を取得する。
`conf.vimgrep_arguments` には telescope が `live_grep` で ripgrep を呼ぶ際のデフォルト引数
（`--vimgrep --color=never --no-heading --with-filename --line-number --column` 等）が入っている。
これをベースに `opts.additional_args` を追加することで、telescope 標準の挙動を維持しつつ
`--hidden` / `--smart-case` などを上乗せできる。

```lua
local grep_args = vim.tbl_flatten({ conf.vimgrep_arguments, opts.additional_args or {} })
--  → { 'rg', '--vimgrep', '--color=never', ..., '--hidden', '--smart-case', '-g', '!.git/' }
```

#### `require('telescope.finders').new_job`

プロンプトの入力内容を受け取って **外部コマンドを動的に切り替える** finder を作成する。
署名: `finders.new_job(fn, entry_maker, max_results, cwd)`

| 引数 | 型 | 説明 |
|---|---|---|
| `fn` | `function(prompt) -> string[]` | プロンプト文字列を受け取りコマンドをリストで返す関数。`nil` を返すと何も実行しない |
| `entry_maker` | `function(line) -> table` | コマンドの標準出力を1行ずつ受け取り、telescope の entry テーブルに変換する関数 |
| `max_results` | `number\|nil` | 表示する最大件数 |
| `cwd` | `string\|nil` | コマンドを実行するワーキングディレクトリ |

プロンプトが変わるたびに `fn` が呼ばれ、返ったコマンドが再実行される。
これを利用して「空なら `rg --files`、入力ありなら `rg <pattern>`」と切り替えている。

#### `require('telescope.make_entry')`

外部コマンドの出力行を telescope が扱える entry テーブルに変換する関数を生成するモジュール。

| 関数 | 対応する出力形式 | 用途 |
|---|---|---|
| `make_entry.gen_from_vimgrep(opts)` | `filename:line:col:text` | `rg --vimgrep` の grep 結果 |
| `make_entry.gen_from_file(opts)` | ファイルパスのみ | `rg --files` のファイル一覧 |

どちらも **関数を返す** ので、返り値を `entry_maker` として使う。
今回は出力行のフォーマットで自動判別している。

```lua
local function entry_maker(line)
  if line:match('^.+:%d+:%d+:') then  -- filename:line:col:text 形式 → grep 結果
    return grep_entry(line)
  end
  return file_entry(line)             -- パスのみ → ファイル一覧
end
```

#### `require('telescope.pickers').new`

実際に表示される UI ピッカーを生成する。
`pickers.new(opts, config):find()` で画面を開く。

| config キー | 内容 |
|---|---|
| `finder` | データソース（`finders.new_job` で作成したもの）|
| `previewer` | 右ペインのプレビュー表示。`conf.grep_previewer` はファイル内容を表示する標準プレビューアー |
| `sorter` | 結果の並び替え方法。`sorters.empty()` は何もしない（rg が返した順序をそのまま使う）|

#### `require('telescope.sorters').empty()`

ソートを行わない no-op ソーター。
ripgrep 自体がファイル順・マッチ順で出力するため、追加のソートは不要。
`live_grep` のように外部コマンドに結果の順序を任せる場合に使う。

---

### クエリ未入力時にファイル一覧を表示する仕組み

telescope 標準の `live_grep` はクエリ未入力時に Result 枠が空になる。
`finders.new_job` でクエリの有無に応じて実行コマンドを切り替えることで対応。

```
クエリなし → rg --files ...  → ファイル一覧を表示
クエリあり → rg <pattern> ... → grep 結果を表示
```

**実装コード (`nvim/init.lua`):**
```lua
local function make_smart_search(opts)
  local conf       = require('telescope.config').values
  local finders    = require('telescope.finders')
  local pickers    = require('telescope.pickers')
  local make_entry = require('telescope.make_entry')
  local sorters    = require('telescope.sorters')

  local grep_args  = vim.tbl_flatten({ conf.vimgrep_arguments, opts.additional_args or {} })
  local grep_entry = make_entry.gen_from_vimgrep(opts)
  local file_entry = make_entry.gen_from_file(opts)

  -- 出力フォーマットで grep 結果かファイル一覧かを自動判別
  local function entry_maker(line)
    if not line or line == '' then return nil end
    if line:match('^.+:%d+:%d+:') then  -- filename:line:col:text 形式
      return grep_entry(line)
    end
    return file_entry(line)             -- ファイルパスのみ
  end

  pickers.new(opts, {
    prompt_title = opts.prompt_title,
    finder = finders.new_job(function(prompt)
      if not prompt or prompt == '' then
        return opts.files_cmd           -- ファイル一覧コマンド
      end
      local cmd = vim.deepcopy(grep_args)
      table.insert(cmd, '--')
      table.insert(cmd, prompt)
      return cmd                        -- grep コマンド
    end, entry_maker, opts.max_results, opts.cwd),
    previewer = conf.grep_previewer(opts),
    sorter    = sorters.empty(),
  }):find()
end

-- git root を起点に検索（[fzf]s）
vim.api.nvim_create_user_command('Search', function(opts)
  local git_root = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
  make_smart_search({
    cwd             = git_root,
    default_text    = opts.args,
    additional_args = { '--hidden', '--smart-case', '-g', '!.git/' },
    files_cmd       = { 'rg', '--files', '--hidden', '--color=never', '-g', '!.git/' },
    prompt_title    = 'Search (git root)',
  })
end, { nargs = '*', bang = true })

-- カレントディレクトリを起点に検索（[fzf]S）
vim.api.nvim_create_user_command('SearchFromCurrDir', function(opts)
  make_smart_search({
    cwd             = vim.fn.getcwd(),
    default_text    = opts.args,
    additional_args = { '--hidden', '--smart-case' },
    files_cmd       = { 'rg', '--files', '--hidden', '--color=never' },
    prompt_title    = 'Search (cwd)',
  })
end, { nargs = '*', bang = true })
```

---

## 変更ファイル一覧

| ファイル | 変更内容 |
|---|---|
| `nvim/init.lua` | telescope Esc 修正、BookmarkHighlight 再定義、smart search 実装 |
| `_vimrc` | Search / SearchFromCurrDir を `if !has('nvim')` で nvim 時に無効化 |

---

## 参考URL

### telescope.nvim 公式

| 内容 | URL |
|---|---|
| telescope.nvim リポジトリ | https://github.com/nvim-telescope/telescope.nvim |
| カスタムピッカー開発ガイド（developers.md） | https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md |
| telescope.nvim wiki | https://github.com/nvim-telescope/telescope.nvim/wiki |

### 関連ソースコード（telescope.nvim 内）

| モジュール | ソースパス |
|---|---|
| `telescope.finders` | `lua/telescope/finders.lua` |
| `telescope.pickers` | `lua/telescope/pickers.lua` |
| `telescope.make_entry` | `lua/telescope/make_entry.lua` |
| `telescope.sorters` | `lua/telescope/sorters.lua` |
| `telescope.config` | `lua/telescope/config.lua` |

ローカルのソースは `~/.local/share/nvim/lazy/telescope.nvim/lua/telescope/` に展開されている。

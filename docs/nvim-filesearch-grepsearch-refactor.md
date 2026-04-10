# nvim: FileSearch / GrepSearch リファクタリング

## 修正概要

### ショートカット変更

| キー | 変更前 | 変更後 |
|------|--------|--------|
| `[fzf]g` | `:GFiles`（fzf.vim） | `:Search`（FileSearch / telescope） |
| `[fzf]s` | `:Search`（FileSearch） | `:GrepSearch`（GrepSearch / telescope） |

### GFiles 削除

`_vimrc` の GFiles コマンド定義と関連マッピング（`[fzf]g`, `[fzf]gs`, `[fzf]G`）を削除。

---

## FileSearch の挙動

`[fzf]g` で起動。git root 配下のファイルを fuzzy 検索する telescope picker。

### キーバインド

| キー | 動作 |
|------|------|
| `<C-r>` | Old Files（最近開いたファイル）に遷移 |
| `<C-b>` | Buffers（開いているバッファ）に遷移 |
| `<C-f>` | プレビュートグル |
| `<C-t>` | 新規タブで開く |
| `<C-v>` | vsplit で開く |
| `<C-h>` | hsplit で開く |

### Old Files / Buffers からの戻り方

FileSearch から `<C-r>` で Old Files に遷移した場合、Old Files 内で再度 `<C-r>` を押すと FileSearch に戻る（`<C-b>` → Buffers も同様）。

```
FileSearch  <C-r>→  Old Files  <C-r>→  FileSearch
FileSearch  <C-b>→  Buffers    <C-b>→  FileSearch
```

### MRU / Buffers に telescope.builtin を使用

fzf.vim の `FZFMru`・`Buffers` ではなく `telescope.builtin.oldfiles`・`telescope.builtin.buffers` を使用。telescope で統一することで UI・キーバインドが一貫する。

---

## GrepSearch の挙動

`[fzf]s` で起動。git root 配下のファイル内文字列を live grep する telescope picker。プレビューはデフォルトで表示。

### キーバインド

| キー | 動作 |
|------|------|
| `<C-f>` | プレビュートグル |
| `<C-t>` | 新規タブで開く |
| `<C-v>` | vsplit で開く |
| `<C-h>` | hsplit で開く |

---

## FileSearch / GrepSearch 間の切り替え廃止

以前は `<C-g>` で FileSearch ↔ GrepSearch を切り替えられたが、廃止。それぞれ独立したショートカットから直接起動する設計に変更。

---

## 実装上のポイント

### `make_file_search` の前方宣言

`open_oldfiles_with_back` / `open_buffers_with_back` が `make_file_search` を参照し、`make_file_search` がそれらを参照する相互参照になるため、Lua の前方宣言を使用。

```lua
local make_file_search  -- forward declaration

local open_oldfiles_with_back = function(file_opts)
  -- make_file_search を参照
end

make_file_search = function(opts)  -- local なし（前方宣言済み）
  -- open_oldfiles_with_back を参照
end
```

---

## Q&A

### Q. `vim.schedule` は telescope で定義されている関数ですか？

いいえ、Neovim 本体の API です。引数のコールバック関数を現在のイベントループが終わった後に実行するよう予約します。

`actions.close` でpickerを閉じた直後に別のpickerを開こうとすると描画が競合することがあるため、`vim.schedule` でワンフレーム遅らせて競合を避けています。

```lua
map('i', '<C-r>', function(b)
  actions.close(b)
  vim.schedule(function() open_oldfiles_with_back(opts) end)
  --  ↑ close後に実行を予約することで描画競合を回避
end)
```

### Q. `actions.close` はどういう機能ですか？

telescope の関数で、picker ウィンドウを閉じる処理です。`prompt_bufnr`（picker のバッファ ID）を受け取り、そのpickerを終了させます。

`map` のコールバック内では `prompt_bufnr` が引数として渡されてくるので、それを `actions.close(b)` に渡すことで「このキーを押したらpickerを閉じる」という動作を定義しています。

### Q. 前方宣言をしている理由は？

Lua では変数は**宣言された時点から下のスコープにしか見えません**。

今回のコードは以下の依存関係があります。

```
open_oldfiles_with_back  →  make_file_search を呼ぶ
make_file_search         →  open_oldfiles_with_back を呼ぶ
```

前方宣言なしに素直に書くと、どちらを先に定義しても片方が未定義になります。

```lua
-- ❌ このように書くと...
local open_oldfiles_with_back = function(file_opts)
  make_file_search(file_opts)  -- まだ定義されていない → nil
end

local make_file_search = function(opts)
  open_oldfiles_with_back(opts)  -- これは見える
end
```

前方宣言を使うと、変数（箱）だけ先に確保しておき、後から中身（関数）を代入できます。**呼び出しは実行時に解決される**ため、代入が終わっていれば問題ありません。

```lua
local make_file_search  -- 箱だけ確保（nil）

local open_oldfiles_with_back = function(file_opts)
  make_file_search(file_opts)  -- 箱は見える。実行時には中身が入っている
end

make_file_search = function(opts)  -- local なし。前方宣言の箱に代入
  open_oldfiles_with_back(opts)
end
```

関数の**定義**と**呼び出し**は別のタイミングです。`open_oldfiles_with_back` を定義する時点では `make_file_search` は nil ですが、実際に**呼び出される**のはユーザーがキーを押した後なので、その時点では代入済みになっています。

# nvim: Search / SearchFromCurrDir 実装 Q&A

## Q. `map('i', '<C-t>', switch)` の `'i'` はショートカットを意味していますか？

いいえ、`'i'` は insert モードを意味します。
telescope のプロンプトはデフォルトで insert モードになっているため、`'i'` で入力中に `<C-t>` が効くようにしています。`'n'` は normal モードで、`<Esc>` を押した後の状態に対応しています。

---

## Q. `previewer = conf.grep_previewer(opts)` の `conf` は Lua で用意されている API ですか？

いいえ、`conf` はその直前で定義したローカル変数です。

```lua
local conf = require('telescope.config').values
```

`require('telescope.config').values` で telescope の設定値テーブルを取得したものを `conf` という名前で使っています。`conf.grep_previewer` は telescope が用意しているプレビューアー関数です。

---

## Q. `function(b)` の `b` はどこで定義されていますか？ `open_in_split(prompt_bufnr, 'vsplit')` とするのは問題ありますか？

`b` はどこにも定義されていません。`function(b)` の `b` 自体が定義です。Lua の無名関数の引数名なので、`b` でも `prompt_bufnr` でも `x` でも何でも構いません。

`open_in_split(prompt_bufnr, 'vsplit')` とすると、`prompt_bufnr` はこのスコープに存在しないローカル変数を参照することになるので問題があります。`function(b)` の `b` のように、`map` から渡される値を受け取る引数が必要です。

```lua
map('i', '<C-v>', function(b) open_in_split(b, 'vsplit') end)
--                         ↑ここで定義        ↑ここで参照
```

`map` がキー押下時にこの無名関数を呼び出し、バッファ番号を引数として渡します。その値を `b` という名前で受け取り、`open_in_split` に渡しています。

---

## Q. `actions.close(prompt_bufnr)` はどういう処理を実行していますか？

telescope のピッカー画面を閉じる処理です。

`open_in_tab` 関数全体の流れは以下のとおりです。

```lua
local open_in_tab = function(prompt_bufnr)
  local entry = action_state.get_selected_entry()  -- 選択中のエントリ（ファイル情報）を取得
  actions.close(prompt_bufnr)                      -- telescope 画面を閉じる
  if entry then
    vim.cmd('tabedit ' .. (entry.path or entry.filename or entry.value))  -- 新規タブで開く
  end
end
```

---

## Q. `map` は neovim 標準関数ですか？

いいえ、`map` は `attach_mappings` のコールバック引数として telescope が渡してくる関数です。

```lua
attach_mappings = function(prompt_bufnr, map)
  --                                     ↑ telescope が渡す map 関数
  map('i', '<C-t>', function(b) open_in_split(b, 'vsplit') end)
end
```

neovim 標準の `vim.keymap.set` とは別物で、telescope のピッカー画面内に限定したキーバインドを登録するために使います。

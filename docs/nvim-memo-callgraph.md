# Memo 起点の呼び出しツリー出力（callgraph）

Memo に付けた「起点マーク」から、LSP を使って関数の呼び出し関係をたどりテキスト出力するツール。

## 構成

| ファイル | 役割 |
|---|---|
| `nvim/lua/rc/memo.lua` | 定型メモ挿入（`<leader>mf`）。起点マークを付ける |
| `etc/callgraph.sh` | エントリポイント。引数解釈と nvim 起動のみ |
| `nvim/lua/tools/callgraph.lua` | 本体。LSP 問い合わせ・探索・整形出力 |
| `nvim/lua/lsp_servers.lua` | サーバー定義。通常起動（`rc/lsp.lua`）と headless で共用 |

シェル側は JSON を扱わない（`jq` 不要）。メモの読み取りも LSP も Lua 側で完結するため、
`sh` さえあれば mac / GitBash のどちらでも同じ手順で動く。

## 使い方

### 1. 起点となる関数にマークを付ける

調べたい関数の定義行にカーソルを置いて `<leader>mf`。
`検索: この関数を起点とした呼び出しを調べる` というメモが `#00FF7F` の色で追加される
（通常のメモ `<leader>ma` と同じく `~/.vim/memos.json` に保存される）。

### 2. ツールを実行する

```sh
etc/callgraph.sh
```

```
memo_add_or_edit  (nvim/lua/rc/memo.lua:112)
　→memo_set_extmark  (nvim/lua/rc/memo.lua:58)
　　→memo_hl_group  (nvim/lua/rc/memo.lua:30)
　→memo_flush_buf  (nvim/lua/rc/memo.lua:70)
　　→memo_normalize_path  (nvim/lua/rc/memo.lua:24)
　　→memo_read_json  (nvim/lua/rc/memo.lua:37)
　　　→memo_normalize_path  (nvim/lua/rc/memo.lua:24)  (既出)
　　→memo_write_json  (nvim/lua/rc/memo.lua:51)
```

起点メモが複数あれば空行区切りで複数のツリーを出力する。

### オプション

| オプション | 既定 | 説明 |
|---|---|---|
| `-k, --keyword TEXT` | 上記の定型文 | 抽出キーワード（位置引数でも指定可） |
| `-r, --root DIR` | git トップレベル | 探索ルート。ここから外れた定義は辿らない |
| `-d, --depth N` | 5 | 最大深さ。打ち切りは `…` で表示 |
| `-o, --output FILE` | 標準出力 | 出力先 |
| `-m, --memo-file PATH` | `~/.vim/memos.json` | メモファイル |
| `--direction out\|in` | out | 呼び出し先 / 呼び出し元 |
| `--format tree\|md\|json` | tree | 出力形式 |
| `--timeout MS` | 30000 | LSP 待ち時間 |
| `--external` | off | ルート外（ライブラリ等）の定義も葉として出力 |
| `--no-loc` | off | 関数名のみ出力し `ファイル:行` を省く |
| `-q, --quiet` | off | 進捗メッセージ（stderr）を抑制 |

マーカーの意味: `(既出)` 別ツリーで展開済み / `(循環)` 祖先に同じ関数 / `…` 深さ打ち切り / `(外部)` ルート外。

## 設計

### なぜ callHierarchy を使わないか

呼び出し先（outgoing）を取る正攻法は `callHierarchy/outgoingCalls` だが、
**lua_ls は callHierarchy に非対応**（`callHierarchyProvider = nil`）で、他サーバーも対応がまちまち。
そこで、ほぼ全てのサーバーが対応する `textDocument/definition` と `textDocument/documentSymbol`
だけで完結する方式を採っている。

1. 起点メモの行から `documentSymbol` で関数シンボルを特定する
   （①メモ行が関数名の行 → ②メモ行を含む関数 → ③メモ行以降で最初の関数、の順に判定）
2. その関数の range 内をスキャンし `識別子(` の形を呼び出し候補として集める
   （文字列リテラルとコメントは同じ長さの空白に置換してから走査するので列位置はずれない）
3. 各候補の位置で `definition` を投げ、定義先が関数シンボルなら呼び出し先とみなす
4. 3 を再帰する

`--direction in` は `textDocument/references` の各参照位置を囲む関数を呼び出し元とみなす。
こちらは全サーバーが対応している。

### 誤検出を防ぐための処理

- **別名の追跡**: `local map_modes = util.map_modes` のような別名宣言に定義が着地した場合、
  宣言行の右辺末尾の識別子からもう一段 `definition` を辿る。TS の import 経由の呼び出しも同じ経路で解決する。
- **シンボリックリンクの解決**: パスは全て `fs_realpath` で正規化する。
  これをしないと `~/.config/nvim` 経由で返る定義がルート外と誤判定される。
- **名前の照合**: 解決したシンボル名と呼び出し名が対応しない場合は捨てる。
  `function M.map_modes(map, key, fn)` の引数 `map` が同じ行の `M.map_modes` に結び付くのを防ぐ。
- **宣言行の除外**: 宣言行にある自分自身の名前は呼び出しとして拾わない。

### headless 実行（`nvim -l`）の前提

`nvim -l` は個人設定を読み込まないため、以下を `lsp_servers.setup_headless()` で自前で組む。

- `rtp` に lazy.nvim 配下の `nvim-lspconfig` を追加する
- mason の `bin` を `PATH` に通す
- filetype 自動判定が働かないので `vim.filetype.match()` で明示的に設定する
  （`FileType` の発火が LSP の attach 契機になるため必須）
- 別インスタンスで開いているファイルを読めるよう `swapfile` を無効化する

## 制限事項

- 関数として扱うのは SymbolKind が Method / Constructor / Function のものだけ。
  `local f = function() end` のように変数へ代入された無名関数は葉にならない。
- 呼び出しの検出は `識別子(` の正規表現ベースなので、
  メソッドチェーンやコールバックとして渡される高階関数の呼び出しは取りこぼす。
  精度を上げるなら nvim-treesitter を導入して構文木の call ノードを使う手がある。
- LSP サーバーが起動できない言語では動かない。このマシンでは
  ts_ls（node の `libllhttp` 欠損）と kotlin_language_server（`JAVA_HOME` が無効）が未起動。

## 動作確認

`nvim/lua/rc/memo.lua` の関数を起点に lua_ls で確認済み。
同一ファイル内の再帰探索、`rc/util.lua` への別ファイル追跡、`(既出)` / `(循環)` / `…` の各マーカー、
`--direction in`、`--format md|json`、複数起点の同時出力が想定どおり動作する。

# nvim: aerial.nvim + 純正LSPクライアント 導入

対応コミット: `7352573`〜`be4da7c`（`git log 7352573^..HEAD -- nvim/init.lua zellij/config.kdl`）

別環境でも同じ状態を再現できるようにするための構築手順・設計メモ。
本プロジェクトは **lazy.nvim を使わず**、`pack/plugins/start/` への手動配置でプラグインを管理している
（`nvim/init.lua` は単一ファイルに全設定を集約する構成）。


---

## 前提: このマシンの LSP 事情

- 補完は元々 `ddc.vim`（`vim-lsp` ソース）を使う想定で `_vimrc` に設定があるが、
  **このマシンには ddc.vim / vim-lsp / skkeleton / denops.vim は未インストール**で、
  `_vimrc` 側は `if exists('*ddc#enable')` ガードにより常に無効（実質死んでいるコード）。
- そのため今回追加した **Neovim 純正LSPクライアント（`vim.lsp`）** が、このマシンで唯一動作する補完手段になる。
- `aerial.nvim` のシンボル取得（`backends = 'lsp'`）も純正LSPクライアントに依存するため、
  aerial 単体では機能せず、LSPクライアント設定が前提になる。


---

## 1. 手動で配置するプラグイン（`pack/plugins/start/` 配下）

| プラグイン | 配置先 | 備考 |
|---|---|---|
| `nvim-lspconfig` | `pack/plugins/start/nvim-lspconfig` | `master` で良い。各サーバーの既定設定（`lsp/*.lua`）を提供するだけで、`require('lspconfig')` は呼ばない |
| `aerial.nvim` | `pack/plugins/start/aerial.nvim` | **nvim-0.11 ブランチ必須**。`master` は `vim.fn.has('nvim-0.12') == 0` の場合 `setup()` の頭でエラーを出して no-op するようになっている |

```bash
git clone https://github.com/neovim/nvim-lspconfig.git \
  ~/AppData/Local/nvim/pack/plugins/start/nvim-lspconfig

git clone --branch nvim-0.11 https://github.com/stevearc/aerial.nvim.git \
  ~/AppData/Local/nvim/pack/plugins/start/aerial.nvim
```

`vim.lsp.enable('xxx')` は `lsp/xxx.lua` を runtimepath 全体から探すため、
`nvim-lspconfig` を pack に置くだけで有効（`require('lspconfig')` の呼び出しは不要）。

---

## 2. `nvim/init.lua` の追加内容

`toggleterm.setup()` の後、`_vimrc` を source する直前に以下を追記済み（該当ブロックはそのまま `nvim/init.lua` を参照）。

### 2-1. 補完ポップアップの前提設定

```lua
vim.opt.completeopt:append({ 'menuone', 'noselect', 'popup' })
```

固定値 `menu,popup` には `noselect`/`menuone` が無く、候補が1件だと表示されなかったり
自動選択で確定挿入されてしまうため追加。

### 2-2. `LspAttach` 共通処理（言語サーバー非依存）

| 処理 | 内容 |
|---|---|
| キーマップ | `gd`（定義）`gr`（参照）`K`（hover）`<leader>rn`（rename）`<leader>ca`（code action）`[d`/`]d`（診断移動）|
| 補完 | `vim.lsp.completion.enable(true, client.id, bufnr, {autotrigger=true})`。**サーバー規定の `triggerCharacters`（`,` ` ` 等）だけでは英数字入力で発火しないため**、`client.server_capabilities.completionProvider.triggerCharacters` を ASCII 32-126 全文字に拡張してから `enable` する |
| インレイヒント | `supports_method('textDocument/inlayHint')` なら `vim.lsp.inlay_hint.enable(true, {bufnr=bufnr})` |
| シグネチャヘルプ | `signatureHelpProvider.triggerCharacters`（通常 `(` `,`）を `InsertCharPre` で監視し、自動で `vim.lsp.buf.signature_help()` |

この処理は特定の言語サーバーに依存しないため、以下で `vim.lsp.enable()` するサーバーすべてに自動適用される。

### 2-3. 言語サーバーごとの有効化

| 言語 | config名 | 有効化条件 | 追加設定 |
|---|---|---|---|
| Lua | `lua_ls` | 常時 | `lua.diagnostics.globals = {'vim'}` 等（Neovim API認識用）|
| C# | `roslyn_ls` | `roslyn-language-server` または `Microsoft.CodeAnalysis.LanguageServer` が実行可能な場合のみ | なし（nvim-lspconfig規定を使用）|
| Swift | `sourcekit` | `sourcekit-lsp` が実行可能な場合のみ | `filetypes = {'swift'}` に絞る（固定は `objc`/`objcpp`/`c`/`cpp` も含むが Xcode ビルドシステム前提のため対象外にした）|

いずれも「実行ファイルが無ければ何もしない」ガード付きなので、未導入マシンで開いてもエラーにならない。


---

## 3. 各言語サーバー本体の導入（このタスクの範囲外・環境ごとに実施）

### Lua (`lua_ls`)

パッケージマネージャ等で導入し、PATH に追加するだけ。追加設定は `nvim/init.lua` 側で完結している。

### C# (`roslyn_ls`)

dotnet tool として導入する（`dotnet` SDK が前提）。

```bash
dotnet tool install --global roslyn-language-server --prerelease \
  --source https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/index.json
```

- インストール先は `~/.dotnet/tools`。GitBash で `which roslyn-language-server` が通ることを確認する
  （通らない場合は `~/.bashrc` 等で `export PATH="$HOME/.dotnet/tools:$PATH"`）
- ルート検出は `.sln`/`.slnx`/`.csproj` の層（`nvim-lspconfig` の `lsp/roslyn_ls.lua` 参照）。
  プロジェクト直下で `dotnet restore` を済ませておくこと
- .NET for Android など Android ワークロードが要る場合は `dotnet workload install android` も必要
  （参照アセンブリが無いとプロジェクトで失敗し補完が効かない）
- 確認：`.cs` を開いて数秒待つと `Roslyn project initialization complete` の通知が出る。それ以降補完が効く

### Swift (`sourcekit`)

`sourcekit-lsp` は Swift ツールチェーンに同梱されており、単体だけを軽量に導入する方法は無い
（コンパイラ・標準ライブラリと不可分）。

- Windows：`winget install --id Swift.Toolchain`（**約1.6GB**。このマシンでは容量を理由に**未導入・保留**）
- 導入する場合は `Package.swift`（SwiftPM）または `.xcodeproj`/`buildServer.json` がプロジェクトルートに必要
- 確認：`:lua print(vim.fn.executable('sourcekit-lsp'))` が `1` を返せば有効化される

---

## 4. zellij 側の追加対応

nvim のジャンプリスト（`<C-o>` で戻る）が zellij の既定キーバインド（`Ctrl o` → セッションモード）に
奪われて届かなかったため、`zellij/config.kdl` の `normal` モードに追加:

```kdl
unbind "Ctrl o" // Neovim のジャンプリスト（戻る）に渡すため
```

既存の `Ctrl n`/`Ctrl p`/`Ctrl f`/`Ctrl t`/`Ctrl h`/`Ctrl l`/`Ctrl g` の unbind と同じ理由・同じ書き方。

**注意**: 設定はセッション作成時に読み込まれるため、既存の起動済みセッションには反映されない。
`zellij kill-session <名前>` で該当セッションを終了し、新規セッションを作り直す必要がある。

---

## 5. aerial.nvim 本体の設定

```lua
require('aerial').setup({
  backends = { 'lsp', 'treesitter', 'markdown', 'man' },
  layout = {
    default_direction = 'right',
    placement = 'edge',
    min_width = 30,
    max_width = { 50, 0.3 },
  },
  attach_mode = 'global',
  close_on_select = false,
  show_guides = true,
  filter_kind = {
    'Class', 'Constructor', 'Enum', 'Function', 'Interface', 'Module',
    'Method', 'Struct', 'Variable', 'Constant', 'Field', 'Property',
  },
  highlight_on_hover = true,
})

vim.keymap.set('n', '<Leader>o', '<Cmd>AerialToggle<CR>',        { silent = true })
vim.keymap.set('n', '<Leader>O', '<Cmd>AerialToggle! right<CR>', { silent = true })
```

`treesitter`/`markdown`/`man` バックエンドは、対応するプラグイン（`nvim-treesitter` 等）が
このマシンには無いため実質フォールバックせず、現状 `lsp` バックエンドのみが機能する。

---

## 6. VS/Visual Studio との差分（既知の制約）

補完エンジン自体（Roslyn/Swift）は VS/Xcode と同じものだが、以下は未対応・簡易実装:

- スニペットのタブストップ間ジャンプ（未確認）
- コードアクションの自動提示（ライトバルブ）。今は `<leader>ca`/`gra` の手動呼び出しのみ
- 補完UIの装飾（種別アイコン等）は無く、テキストのみのポップアップ

インレイヒント・シグネチャヘルプ自動表示は導入済み（本ドキュメント §2-2）。

---

## 動作確認チェックリスト

1. `nvim-lspconfig` / `aerial.nvim`(nvim-0.11) を pack に配置し、起動時にエラーが出ない
2. Lua ファイルで `gd`/`K`/補完ポップアップが効く
3. `<Leader>o` / `<Leader>O` でアウトラインが右端に開き、シンボルが表示される
4. C#: `roslyn-language-server` 導入後、`.sln`/`.csproj` 配下の `.cs` で補完・`gd`・診断が効く
5. `<C-o>`/`<C-i>` でジャンプ前後に移動できる（zellij の config.kdl 反映後の新規セッションで）
6. 言語サーバー未導入の場合でも nvim 起動時にエラー通知が出ない

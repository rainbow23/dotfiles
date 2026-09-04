# dotfiles フォルダ構成

2026-07 の構成改善（init.lua 分割・fzf 一元管理）後の構成資料。

## 全体構成

```
dotfiles/
├── _vimrc                  # vim/nvim 共通の VimScript 設定（~/.vimrc にリンク）
├── _bashrc / _tmux.conf / _ideavimrc
├── zsh/                    # zsh 設定（_zshrc, _zshenv）
├── etc/                    # その他ツール設定（karabiner など）
├── symlink.sh              # シンボリックリンク作成スクリプト
├── source.sh / mru.sh      # シェル用スクリプト
├── docs/                   # ドキュメント
├── zellij/                 # Zellij 設定（config.kdl → ~/.config/zellij/ にリンク）
├── vimrc.d/                # _vimrc から source する分割 VimScript 設定
│   ├── search-keymaps.vim  # 検索系キーマップと fzf 共通設定（vim/nvim 共通）
│   ├── fzf.vim             # fzf ベースの実装（telescope 置き換え済みコマンドは plain vim のみ）
│   └── gitbash.vim         # GitBash(Windows) 特有の設定（パス変換+clip コピー）
└── nvim/                   # nvim 設定（~/.config/nvim にディレクトリごとリンク）
    ├── init.lua            # ローダー: bootstrap → config(pre) → lazy → _vimrc → config(post) → rc
    ├── lazy-lock.json      # lazy.nvim のロックファイル
    └── lua/
        ├── plugins/        # プラグインの読み込み定義のみ（設定値は持たない）
        │   ├── core.lua        # 設定不要（g: 変数のみで動く）プラグイン群
        │   ├── nerdtree.lua    # NERDTree 本体と関連プラグイン
        │   ├── telescope.lua   # telescope 本体
        │   ├── bookmarks.lua   # bookmarks.nvim（init のモンキーパッチのみ）
        │   ├── toggleterm.lua  # toggleterm
        │   ├── aerial.lua      # aerial.nvim（アウトライン表示）
        │   ├── render-markdown.lua # render-markdown.nvim
        │   └── lsp.lua         # LSP/補完系のプラグイン定義
        ├── config/         # 各プラグインの設定値（lazy 非依存。手動配置でも require で読める）
        │   ├── nerdtree.lua    # g:NERDTreeMapActivateNode（ロード前に require）
        │   ├── bufexplorer.lua # g:bufExplorerDisableDefaultKeyMapping（ロード前に require）
        │   ├── telescope.lua   # telescope setup / 共通レイアウト・マッピング
        │   ├── toggleterm.lua  # toggleterm setup + tig float
        │   ├── bookmarks.lua   # bookmarks setup + キーマップ + highlight
        │   ├── aerial.lua      # aerial setup + キーマップ（<Leader>o トグル等）
        │   ├── render-markdown.lua # render-markdown setup
        │   ├── smart-splits.lua    # smart-splits setup + Ctrl+hjkl ペイン移動
        │   └── win32.lua       # Windows 固有の設定
        └── rc/             # 自作の機能モジュール
            ├── util.lua        # telescope 共通ユーティリティ（レイアウトプリセット等）
            ├── search.lua      # FileSearch/GrepSearch/BLines/FZFMru（telescope）
            ├── session.lua     # セッション管理（telescope）
            ├── memo.lua        # extmarks ベースのメモ機能
            ├── zoom.lua        # float window による疑似最大化（,,）
            ├── ui.lua          # highlight 復元・tabline・リサイズ均等化
            ├── lsp.lua         # LSP/補完のセットアップ処理
            └── patches/
                └── bookmarks.lua  # bookmarks.nvim へのモンキーパッチ
```

## フォルダ名の略語

- **`rc/`** — "run commands" の略。`.vimrc` `.bashrc` などの「rc」と同じで、
  起動時に読み込まれる設定・初期化コードを意味する Unix の慣習。
  ここでは「プラグイン定義（plugins/）ではない自作の設定モジュール」を置く場所。
  `require('rc.search')` のように名前空間として使うことで、
  プラグインが提供する Lua モジュール名（`util` `lsp` など汎用名）との衝突も避けている。
- **`vimrc.d/`** — `.d` は "directory" の略。`/etc/conf.d/` `/etc/init.d/` `logrotate.d` などと同じ、
  「1 ファイルの設定を分割して置くディレクトリ」を表す Unix の慣習。
  `_vimrc` から source される分割設定ファイル置き場。

## 読み込みフロー

### nvim

```
~/.config/nvim → dotfiles/nvim（ディレクトリごとリンク）

init.lua
 ├── ① lazy.nvim bootstrap
 ├── ② mapleader 設定
 ├── ②' require('config.*')（ロード前設定）  … プラグインロード前に確定が必要な g: 変数
 ├── ③ require('lazy').setup('plugins')   … lua/plugins/*.lua を自動読込
 ├── ④ source ~/dotfiles/_vimrc
 │       └── vimrc.d/search-keymaps.vim / vimrc.d/fzf.vim を source
 ├── ⑤ nvim 向け上書き（autochdir 無効化）
 ├── ⑤' require('config.*')（ロード後設定）  … telescope/toggleterm/bookmarks の setup 等
 └── ⑥ require('rc.*')                    … 機能モジュール
```

### plain vim

```
~/.vimrc → dotfiles/_vimrc

_vimrc
 ├── vimrc.d/search-keymaps.vim  … キーマップと fzf 共通設定
 └── vimrc.d/fzf.vim             … fzf 実装（if has('nvim') | finish 以降が有効になる）
```

## 検索系コマンドの実装対応表

キーマップは `vimrc.d/search-keymaps.vim` の 1 箇所で定義し、
同名コマンドの実装を環境ごとに用意する。

| キー | コマンド | nvim 実装 | plain vim 実装 |
|---|---|---|---|
| `[fzf]f` | FileSearch | rc/search.lua (telescope) | なし |
| `[fzf]s` | GrepSearch | rc/search.lua (telescope) | vimrc.d/fzf.vim (fzf) |
| `[fzf]l` | BLines | rc/search.lua (telescope) | fzf.vim プラグイン |
| `[fzf]m` | FZFMru | rc/search.lua (telescope oldfiles) | vimrc.d/fzf.vim (fzf) |
| `[fzf]us` | MySessionLoad | rc/session.lua (telescope) | vimrc.d/fzf.vim (fzf) |
| `[fzf]g` | GitStatus | rc/search.lua (telescope) | なし |
| `[fzf]b` | Buffers | fzf.vim プラグイン | fzf.vim プラグイン |
| `[fzf]c` | GrepCache | rc/search.lua (telescope) | なし |
| `[fzf]h` / `[fzf]w` | History / Windows | fzf.vim プラグイン | fzf.vim プラグイン |
| `[fzf]y` | FZFYank | vimrc.d/fzf.vim ※easyclip 未導入のため実質無効 | 同左 |

`[fzf]` プレフィックスは `<Leader>f`（Space + f）。

## Zellij / tmux ペイン・ウィンドウ移動

### キーマップ一覧

| キー | Zellij (GitBash) | tmux (Mac) |
|---|---|---|
| `<C-hjkl>` | Neovim 内スプリット移動（smart-splits.nvim） | Neovim 内スプリット移動 + 端で tmux ウィンドウ移動 |
| `Alt+hjkl` | Zellij ペイン移動（Neovim 有無問わず） | — |
| `Ctrl+u` → `p`/`n` | Zellij タブ移動 | — |
| `Ctrl+u` → 矢印 | Zellij ペイン移動 | — |

### 構成ファイル

| ファイル | 役割 |
|---|---|
| `zellij/config.kdl` | Zellij キーバインド（`~/.config/zellij/config.kdl` にシンボリックリンク） |
| `nvim/lua/config/smart-splits.lua` | smart-splits.nvim setup + `<C-hjkl>` キーマップ |
| `nvim/lua/plugins/core.lua` | smart-splits.nvim プラグイン定義 |
| `vimrc.d/gitbash.vim` | GitBash 用 `<C-h>`/`<C-l>` フォールバック（smart-splits 未導入環境向け） |

### smart-splits.nvim の動作

- tmux / zellij を **自動検出**（`multiplexer_integration` 未指定）
- Neovim 内にスプリットがあれば内部移動、端に達したらターミナルペイン移動を試みる
- tmux: `at_edge` カスタム関数で端ペインから前後ウィンドウへ移動
- zellij: `zellij_move_focus_or_tab = true` で端ペインからタブ移動

### Zellij での制約

Zellij は GitBash/Windows 環境で `RUNNING_COMMAND: N/A` を返すため、
vim-zellij-navigator による Neovim 自動検出が機能しない。
そのため `<C-hjkl>` を unbind して Neovim にパススルーし、
Zellij ペイン移動は `Alt+hjkl` で行う方式を採用している。

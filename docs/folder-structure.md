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
├── vimrc.d/                # _vimrc から source する分割 VimScript 設定
│   ├── search-keymaps.vim  # 検索系キーマップと fzf 共通設定（vim/nvim 共通）
│   └── fzf.vim             # fzf ベースの実装（telescope 置き換え済みコマンドは plain vim のみ）
└── nvim/                   # nvim 設定（~/.config/nvim にディレクトリごとリンク）
    ├── init.lua            # ローダー: bootstrap → lazy → _vimrc source → require
    ├── lazy-lock.json      # lazy.nvim のロックファイル
    └── lua/
        ├── plugins/        # lazy.nvim のプラグイン定義（自動読込）
        │   ├── core.lua        # 設定不要（g: 変数のみで動く）プラグイン群
        │   ├── telescope.lua   # telescope 本体と共通設定
        │   ├── bookmarks.lua   # bookmarks.nvim（spec + config）
        │   ├── toggleterm.lua  # toggleterm（tig float）
        │   └── lsp.lua         # LSP/補完系のプラグイン定義のみ
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
 ├── ③ require('lazy').setup('plugins')   … lua/plugins/*.lua を自動読込
 ├── ④ source ~/dotfiles/_vimrc
 │       └── vimrc.d/search-keymaps.vim / vimrc.d/fzf.vim を source
 ├── ⑤ nvim 向け上書き（autochdir 無効化）
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
| `[fzf]S` | FileSearchFromCurrDir | rc/search.lua (telescope) | なし |
| `[fzf]l` | BLines | rc/search.lua (telescope) | fzf.vim プラグイン |
| `[fzf]m` | FZFMru | rc/search.lua (telescope oldfiles) | vimrc.d/fzf.vim (fzf) |
| `[fzf]us` | MySessionLoad | rc/session.lua (telescope) | vimrc.d/fzf.vim (fzf) |
| `[fzf]g` | GitStatus | rc/search.lua (telescope) | なし |
| `[fzf]b` | MyBuffersMemos | rc/memo.lua (telescope) | なし |
| `[fzf]h` / `[fzf]w` | History / Windows | fzf.vim プラグイン | fzf.vim プラグイン |
| `[fzf]y` | FZFYank | vimrc.d/fzf.vim ※easyclip 未導入のため実質無効 | 同左 |

`[fzf]` プレフィックスは `<Leader>f`（Space + f）。

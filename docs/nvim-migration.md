# nvim移行対応: プラグイン管理をvim-plug → lazy.nvimへ

## 概要

プラグイン管理をvim（vim-plug）からNeovim（lazy.nvim）へ移行しました。

## 変更ファイル一覧

| ファイル | 変更内容 |
|---|---|
| `_vimrc` | vim-plug によるプラグイン定義ブロックを削除 |
| `symlink.sh` | シンボリックリンク先を `_vimrc` → `nvim/init.lua` に変更 |
| `nvim/init.lua` | 新規追加：lazy.nvim を使ったNeovim専用プラグイン設定 |

## 詳細

### `_vimrc` の変更

vim-plug の自動インストール処理およびプラグイン定義（`call plug#begin()` 〜 `call plug#end()`）を削除。
既存のキーマップ・オプション設定はそのまま残し、`nvim/init.lua` から `source` して利用する。

### `symlink.sh` の変更

```diff
- ln -sfn $HOME/dotfiles/_vimrc $HOME/.config/nvim/init.vim
+ ln -sfn $HOME/dotfiles/nvim/init.lua $HOME/.config/nvim/init.lua
```

Neovimの設定エントリーポイントを `init.vim` から `init.lua` に変更。

### `nvim/init.lua` の新規追加

lazy.nvim を使ったNeovim用プラグイン設定ファイル。主な構成：

1. **lazy.nvim の自動インストール**: 未インストール時にgit cloneで取得
2. **mapleader の設定**: `<Space>` をleaderキーに設定
3. **プラグイン定義**: vim-plugで管理していた全プラグインをlazy.nvim形式に移行
4. **VimScript設定の読み込み**: `vim.cmd('source ~/dotfiles/_vimrc')` で既存設定を継続利用

#### 主なプラグイン（カテゴリ別）

- FZF: `junegunn/fzf.vim`, `vim-easy-align`, `vim-peekaboo`
- Unite: `Shougo/unite.vim`, `unite-session`, `unite-outline` 等
- Denops/DDC: `ddc.vim`, `ddc-ui-native`, `ddc-around` 等
- UI: `vim-airline`, `indentLine`, `vim-cursorword` 等
- Git: `vim-fugitive`, `vim-gitgutter`, `tig-explorer.vim` 等
- LSP: `vim-lsp`, `vim-lsp-settings`, `sqls.vim` 等
- Go: `vim-go`, `gocode`, `vim-goimports`
- Bookmarks: `heilgar/bookmarks.nvim`（新規追加）

## 移行の背景

- vim-plug はvimとNeovimの両方で動作するが、Neovimネイティブの設定（Lua API）を活用するため lazy.nvim へ移行
- `_vimrc` はVimScript設定を保持し、`nvim/init.lua` から `source` することで段階的な移行を実現

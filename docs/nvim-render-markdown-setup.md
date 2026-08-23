# nvim: render-markdown.nvim 導入

対応コミット: `nvim/lua/plugins/render-markdown.lua` / `nvim/lua/config/render-markdown.lua` 追加時

別環境で lazy.nvim を使わず再現する場合の手順メモ。  
lazy.nvim 環境では `plugins/render-markdown.lua` + `config/render-markdown.lua` + `init.lua` 追記だけで完結するため、本ドキュメントは **lazy.nvim を使わない環境向け**。

---

## 1. 配置するプラグイン（`pack/plugins/start/` 配下）

| プラグイン | 用途 | 備考 |
|---|---|---|
| `render-markdown.nvim` | Markdown レンダリング本体 | |
| `nvim-treesitter` | シンタックス解析（必須依存） | 既に配置済みなら不要 |
| `nvim-web-devicons` | アイコン表示（任意依存） | 無くても動作する |

```bash
# render-markdown.nvim 本体
git clone https://github.com/MeanderingProgrammer/render-markdown.nvim.git \
  ~/.local/share/nvim/site/pack/plugins/start/render-markdown.nvim

# nvim-treesitter（未導入の場合）
git clone https://github.com/nvim-treesitter/nvim-treesitter.git \
  ~/.local/share/nvim/site/pack/plugins/start/nvim-treesitter

# nvim-web-devicons（任意・アイコンを使う場合）
git clone https://github.com/nvim-tree/nvim-web-devicons.git \
  ~/.local/share/nvim/site/pack/plugins/start/nvim-web-devicons
```

> **macOS のデフォルトパス**: `~/.local/share/nvim/site/`  
> **Windows (GitBash)**: `~/AppData/Local/nvim/site/`

---

## 2. treesitter パーサのインストール

プラグイン配置後、nvim を起動して以下を実行:

```
:TSInstall markdown markdown_inline
```

`markdown_inline` は見出し・インラインコード等のパース精度向上に必要。  
インストール後に再起動すると Markdown ファイルでレンダリングが有効になる。

---

## 3. init.lua への追記

`nvim-lspconfig` や `aerial.nvim` の setup 呼び出しと同じ位置（プラグインロード後）に追記する:

```lua
require('render-markdown').setup({
  -- 見出し: 背景色なし（backgrounds = {} で無効化）
  heading = {
    enabled = true,
    sign = false,
    backgrounds = {},
  },
  -- コードブロック: 背景色なし（highlight = '' で無効化）
  code = {
    enabled = true,
    sign = false,
    style = 'normal',
    highlight = '',
  },
  checkbox = {
    enabled = true,
  },
})

vim.keymap.set('n', '<Leader>m', '<Cmd>RenderMarkdown toggle<CR>', { silent = true })
```

---

## 4. 動作確認チェックリスト

1. `.md` ファイルを開いたとき、見出し（`#`）に背景色が付く
2. コードブロック（` ``` `）に背景が付く
3. `- [ ]` / `- [x]` がチェックボックスアイコンに変わる
4. `<Leader>m` でレンダリングのオン/オフが切り替わる
5. nvim 起動時に `render-markdown` 関連のエラーが出ない

---

## 5. トラブルシューティング

### レンダリングが効かない

- `:checkhealth render-markdown` を実行してエラー内容を確認する
- `nvim-treesitter` が未インストール、または `markdown`/`markdown_inline` パーサが無い場合が最多原因
- `:TSInstall markdown markdown_inline` を再実行し、nvim を再起動する

### アイコンが □ や ? になる

- `nvim-web-devicons` が未インストール、または Nerd Fonts 非対応フォントを使っている
- Nerd Fonts 対応フォントに変更する（例: `JetBrainsMono Nerd Font`）か、`sign = false` を維持してアイコン表示を抑制する

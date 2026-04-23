# nvim: LSP / コード補完 設定

## 概要

nvim 0.11 + nvim-lspconfig v3 対応の LSP / 補完環境。
ddc.vim・vim-lsp を削除し、mason.nvim + nvim-cmp + nvim-lspconfig に移行。

---

## 構成プラグイン

| プラグイン | 役割 |
|---|---|
| `williamboman/mason.nvim` | LSP サーバーのインストール管理 |
| `williamboman/mason-lspconfig.nvim` | mason と nvim-lspconfig の橋渡し |
| `neovim/nvim-lspconfig` | LSP クライアント設定 |
| `hrsh7th/nvim-cmp` | 補完エンジン |
| `hrsh7th/cmp-nvim-lsp` | LSP 補完ソース |
| `hrsh7th/cmp-buffer` | バッファ補完ソース |
| `hrsh7th/cmp-path` | パス補完ソース |
| `L3MON4D3/LuaSnip` | スニペットエンジン |
| `saadparwaiz1/cmp_luasnip` | LuaSnip の nvim-cmp ソース |
| `mfussenegger/nvim-jdtls` | Java 専用 LSP クライアント |

---

## LSP サーバー

| 言語 | サーバー | インストール方法 |
|---|---|---|
| Java | `jdtls` | `:MasonInstall jdtls`（手動） |
| Kotlin | `kotlin_language_server` | mason 自動（ensure_installed） |
| TypeScript / JavaScript | `ts_ls` | mason 自動（ensure_installed） |
| SQL | `sqlls` | mason 自動（ensure_installed） |
| Lua | `lua_ls` | mason 自動（ensure_installed） |
| VimScript | `vimls` | mason 自動（ensure_installed） |
| ShellScript | `bashls` | mason 自動（ensure_installed） |

---

## キーマップ

### LSP（ファイルを開いた後 LspAttach で有効になる）

| キー | 機能 |
|---|---|
| `gd` | 定義へジャンプ |
| `gr` | 参照一覧 |
| `K` | ホバードキュメント表示 |
| `<leader>rn` | シンボルリネーム |
| `<leader>ca` | コードアクション |
| `[d` | 前の診断エラーへ移動 |
| `]d` | 次の診断エラーへ移動 |

### nvim-cmp（補完）

| キー | 機能 |
|---|---|
| `<C-Space>` | 補完を強制表示 |
| `<Tab>` | 次の候補 / スニペット展開・ジャンプ |
| `<S-Tab>` | 前の候補 / スニペット逆ジャンプ |
| `<CR>` | 選択中の候補を確定 |
| `<C-e>` | 補完を閉じる |

---

## 参考 URL

- nvim-cmp キーマップ: https://github.com/hrsh7th/nvim-cmp#recommended-configuration
- nvim LSP キーマップ: https://neovim.io/doc/user/lsp.html
- nvim-lspconfig 0.11 移行ガイド: https://github.com/neovim/nvim-lspconfig/blob/master/doc/lspconfig-nvim-0.11.md
- mason.nvim: https://github.com/williamboman/mason.nvim
- nvim-jdtls: https://github.com/mfussenegger/nvim-jdtls

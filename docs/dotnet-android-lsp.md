# .NET for Android の C# 補完（roslyn_ls）セットアップ

nvim で .NET for Android プロジェクトの C# 補完を有効にする手順。
LSP は Microsoft 公式の Roslyn Language Server（VS Code の C# 拡張と同じもの）を使う。

- nvim 側の設定は [nvim/lua/rc/lsp.lua](../nvim/lua/rc/lsp.lua) に組み込み済み
  （nvim-lspconfig 標準の `roslyn_ls` 設定を使用。`roslyn-language-server` が
  PATH にあるマシンでのみ自動有効化される）
- サーバー本体は mason 管理外。以下の手順で dotnet tool として導入する

## GitBash（Windows）での導入手順

### 1. .NET SDK

インストール済みか確認:

```bash
dotnet --version
```

なければ winget などで導入（PowerShell / コマンドプロンプト）:

```
winget install Microsoft.DotNet.SDK.9
```

### 2. Android ワークロード

Mono.Android などの参照アセンブリはここから供給される。
これがないとプロジェクトロードが失敗し補完が効かない。

```bash
dotnet workload install android
```

※ 権限エラーになる場合は管理者権限のターミナルで実行する。

### 3. Roslyn Language Server

```bash
dotnet tool install -g roslyn-language-server --prerelease --source https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/index.json
```

インストール先は `%USERPROFILE%\.dotnet\tools`（GitBash では `~/.dotnet/tools`）。
GitBash で見えるか確認:

```bash
which roslyn-language-server
```

見つからない場合は PATH に追加する（~/.bashrc など）:

```bash
export PATH="$HOME/.dotnet/tools:$PATH"
```

### 4. プロジェクト側の準備

補完はソリューションの design-time build が通ることが前提。
プロジェクトディレクトリで初回 restore を済ませておく:

```bash
dotnet restore
```

## 動作確認

1. プロジェクト内の .cs ファイルを nvim で開く
2. `:checkhealth vim.lsp` または `:LspInfo` で roslyn_ls がアタッチされていることを確認
3. しばらく待つと「Roslyn project initialization complete」の通知が出る
   （大きいプロジェクトでは初期化に時間がかかる。補完が効くのは初期化完了後）
4. `Android.*` 名前空間や `Activity` 型で補完・`gd`（定義ジャンプ）を確認

ルート検出は .sln / .slnx を優先し、なければ .csproj にフォールバックする。

## トラブルシューティング

- **補完が効かない / 型が解決されない**: `dotnet restore` の成否と
  `dotnet workload list` に android があるかを確認
- **サーバーログ**: `$TMPDIR/roslyn_ls/logs`（Windows は `%TEMP%\roslyn_ls\logs`）
- **サーバー更新**: `dotnet tool update -g roslyn-language-server --prerelease --source <上記 feed URL>`

## 将来の拡張候補

- nvim 0.12 更新後: [seblyng/roslyn.nvim](https://github.com/seblyng/roslyn.nvim)
  （複数 .sln の対話切替 `:Roslyn target` などが必要になった場合）

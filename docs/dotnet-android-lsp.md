# .NET for Android の C# 補完（roslyn_ls）セットアップ

nvim で .NET for Android プロジェクトの C# 補完を有効にする手順。
LSP は Microsoft 公式の Roslyn Language Server（VS Code の C# 拡張と同じもの）を使う。

- nvim 側の設定は [nvim/lua/rc/lsp.lua](../nvim/lua/rc/lsp.lua) に組み込み済み
  （nvim-lspconfig 標準の `roslyn_ls` 設定を使用。`roslyn-language-server` が
  PATH にあるマシンでのみ自動有効化される）
- サーバー本体は mason 管理外。以下の手順で dotnet tool として導入する

## macOS での導入手順（動作確認済み）

Homebrew で導入する。環境変数の設定は [zsh/_zshenv](../zsh/_zshenv) に組み込み済み。

### 1. .NET SDK

```bash
brew install dotnet
```

Homebrew 版は `bin`（muxer のシムのみ）と `libexec`（実体 + ランタイム）が
分離している点が要注意。**`DOTNET_ROOT` と PATH を _zshenv で設定済み**なので、
新しいシェルを開けば有効になる（下記「よくある落とし穴」参照）。

### 2. Android ワークロード

```bash
dotnet workload install android
```

### 3. Roslyn Language Server

```bash
dotnet tool install -g roslyn-language-server --prerelease --source https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/index.json
```

インストール先は `~/.dotnet/tools`（PATH は _zshenv で追加済み）。確認:

```bash
exec $SHELL -l
which dotnet roslyn-language-server
echo "DOTNET_ROOT=$DOTNET_ROOT"
```

`dotnet` が `/opt/homebrew/opt/dotnet/libexec/dotnet` を指していれば正しい。

### 4. サンプルプロジェクトで動作確認

android テンプレートが未登録な環境向けに、テンプレート非依存の最小サンプルを
[docs/samples/dotnet-android/](samples/dotnet-android/) に用意した。任意の場所にコピーして使う:

```bash
cp -r ~/dotfiles/docs/samples/dotnet-android ~/dotnet-android-sample
cd ~/dotnet-android-sample
dotnet workload restore
dotnet restore
```

`dotnet build` は Android SDK Platform（android.jar）が無いと XA5207 で失敗するが、
**補完に必要なのは参照アセンブリ（Mono.Android.dll）だけで、フルビルドは不要**。

その後 nvim で `MainActivity.cs` を開くと roslyn_ls がアタッチし、数秒で
「Roslyn project initialization complete」が表示され、`Android.*` 型が補完される。

### よくある落とし穴（macOS / Homebrew）

- **`You must install .NET to run this application`（roslyn LS が exit 131）**:
  apphost がランタイムを PATH 上の `dotnet` から探すが、`/opt/homebrew/bin/dotnet` は
  シムのみでランタイムを含まない `bin` を指すため失敗する。
  **ランタイム同梱の `libexec` を PATH 前方に置く**ことで解決する（_zshenv 設定済み）。
  `DOTNET_ROOT` の設定だけでは不十分な点に注意（roslyn の wrapper が
  PATH 上の dotnet から `DOTNET_ROOT` を再導出して inner プロセスに渡すため）。

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

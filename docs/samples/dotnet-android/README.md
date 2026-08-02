# .NET for Android 補完確認用サンプル

nvim + roslyn_ls で C# 補完が効くかを確認するための最小プロジェクト。
セットアップ全体は [../../dotnet-android-lsp.md](../../dotnet-android-lsp.md) を参照。

テンプレート（`dotnet new android`）が使えない環境でも動くよう、
テンプレート非依存の手書き構成にしてある。

## 使い方

```bash
cp -r ~/dotfiles/docs/samples/dotnet-android ~/dotnet-android-sample
cd ~/dotnet-android-sample
dotnet workload restore   # 参照アセンブリを取得
dotnet restore
```

nvim で `MainActivity.cs` を開き、数秒後に「Roslyn project initialization
complete」が出れば補完可能。`MainActivity.cs` 内の「補完確認ポイント」の
コメント箇所で `Android.*` 型やメンバー補完を試す。

- `dotnet build`（フル APK ビルド）は Android SDK Platform が別途必要で
  XA5207 が出るが、補完確認には不要。
- `<TargetFramework>` はインストール済み SDK に合わせて調整する
  （このサンプルは `net10.0-android`）。

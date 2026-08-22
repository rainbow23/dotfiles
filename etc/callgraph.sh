#!/bin/sh
# Memo（~/.vim/memos.json）を起点に関数の呼び出し関係を LSP でたどりテキスト出力する
#
# 実処理は nvim/lua/tools/callgraph.lua が行う。
# このスクリプトは引数の受け渡しと nvim 起動のみを担当し、
# jq や GNU 版コマンドに依存しないことで環境差の影響を受けないようにしている。
set -e

SELF_DIR=$(dirname "$0")
CALLGRAPH_LUA="$SELF_DIR/../nvim/lua/tools/callgraph.lua"

usage() {
    cat <<'USAGE'
使い方: callgraph.sh [オプション] [キーワード]

  Memo のテキストにキーワードを含む行を起点として、
  その関数の呼び出し関係をたどりツリー形式で出力する。

オプション:
  -k, --keyword TEXT     抽出キーワード（位置引数でも指定可）
                         既定: 検索: この関数を起点とした呼び出しを調べる
  -r, --root DIR         探索ルート（既定: git のトップレベル、無ければカレント）
  -d, --depth N          最大深さ（既定: 5）
  -o, --output FILE      出力先ファイル（既定: callgraph.txt）
                         tee で標準出力と同時に書き出し、
                         最後に outputPath と内容を再表示する
  -m, --memo-file PATH   メモファイル（既定: ~/.vim/memos.json）
      --direction out|in 呼び出し先（既定）/ 呼び出し元
      --format tree|md|json  出力形式（既定: tree）
      --timeout MS       LSP 待ち時間（既定: 30000）
      --external         ルート外（ライブラリ等）の定義も葉として出力する
      --no-loc           関数名のみ出力し ファイル:行 を省く
  -q, --quiet            進捗メッセージを出さない
  -h, --help             このヘルプ

環境変数:
  NVIM_BIN               使用する nvim の実行ファイル（既定: nvim）
  CALLGRAPH_OUT          出力先ファイルの既定値（既定: callgraph.txt）

例:
  etc/callgraph.sh
  etc/callgraph.sh -d 3 -o callgraph.txt
  etc/callgraph.sh --direction in --format md "呼び出し元を調べる"
USAGE
}

# 引数の先読み: ヘルプ、ルート指定の有無、出力先を取り出す
# 出力先はこのスクリプト側で tee に渡すため、Lua へ渡す引数からは取り除く
# （先頭から取り出して末尾へ積み直すことで、空白を含む引数も壊さずに組み直す）
out=""
args_has_root=0
argc=$#
i=0
while [ "$i" -lt "$argc" ]; do
    arg=$1
    shift
    i=$((i + 1))
    case "$arg" in
        -h|--help)
            usage
            exit 0
            ;;
        -o|--output)
            out=$1
            shift
            i=$((i + 1))
            ;;
        -r|--root)
            args_has_root=1
            set -- "$@" "$arg"
            ;;
        *)
            set -- "$@" "$arg"
            ;;
    esac
done

[ -n "$out" ] || out=${CALLGRAPH_OUT:-callgraph.txt}

# --root 未指定なら git のトップレベルを使う
if [ "$args_has_root" -eq 0 ]; then
    if root=$(git rev-parse --show-toplevel 2>/dev/null) && [ -n "$root" ]; then
        set -- --root "$root" "$@"
    fi
fi

NVIM=${NVIM_BIN:-nvim}
if ! command -v "$NVIM" >/dev/null 2>&1; then
    echo "callgraph: nvim が見つかりません（NVIM_BIN で指定できます）" >&2
    exit 1
fi

if [ ! -f "$CALLGRAPH_LUA" ]; then
    echo "callgraph: 本体が見つかりません: $CALLGRAPH_LUA" >&2
    exit 1
fi

# tee で標準出力とファイルへ同時に書き出す
# パイプの終了ステータスは tee のものになるため、nvim の結果は一時ファイルで受け渡す
# if で受けるのは set -e による即時終了を避けるため（そのままだと終了コードを記録できない）
status_file=$(mktemp)
{
    if "$NVIM" -l "$CALLGRAPH_LUA" "$@"; then
        echo 0 > "$status_file"
    else
        echo $? > "$status_file"
    fi
} | tee "$out"
status=$(cat "$status_file")
rm -f "$status_file"

if [ "$status" -ne 0 ]; then
    exit "$status"
fi

# 出力パスと、出力ファイルの内容を表示する
# 相対指定でも絶対パスで示す（realpath は環境差があるため PWD を前置する）
case "$out" in
    /* | [A-Za-z]:[/\\]*) out_abs=$out ;;
    *)                     out_abs="$PWD/$out" ;;
esac

echo
echo "outputPath: $out_abs"
cat "$out"

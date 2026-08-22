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
  -o, --output FILE      出力先ファイル（既定: 標準出力）
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

例:
  etc/callgraph.sh
  etc/callgraph.sh -d 3 -o callgraph.txt
  etc/callgraph.sh --direction in --format md "呼び出し元を調べる"
USAGE
}

# --root 未指定なら git のトップレベルを使う
root=""
args_has_root=0

# ヘルプとルート指定の有無だけ先読みする（他の引数は Lua 側で解釈する）
for a in "$@"; do
    case "$a" in
        -h|--help) usage; exit 0 ;;
        -r|--root) args_has_root=1 ;;
    esac
done

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

exec "$NVIM" -l "$CALLGRAPH_LUA" "$@"

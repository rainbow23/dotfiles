" GitBash (Windows) 特有の設定
" _vimrc から source される。vim/nvim 共通。
" このファイル全体を Windows 以外では無効化する（mac/unix では何もしない）。
if !(has('win32') || has('win64'))
  finish
endif

" ファイルパスを GitBash 形式（C:\... → /c/...）へ変換してクリップボード（clip）へコピーし、
" 変換後のパスを返す。_vimrc の CopyFilePath() から Windows 環境でのみ呼ばれる。
function! GitBashCopyPath(path) abort
  let l:copy_path = substitute(a:path, '^\([A-Za-z]\):', '/\L\1', '')
  let l:copy_path = substitute(l:copy_path, '\\', '/', 'g')
  call system('printf "%s" "' . l:copy_path . '" | clip')
  return l:copy_path
endfunction

" GitBash 上で :! 経由のシェル実行（デリート等）を正しく動作させるための設定
set shellcmdflag=-c
set shellxquote=
set shellquote=

" pack/plugins/start/ への手動配置プラグイン（fzf）を runtimepath に追加
" mac/unix は vimrc.d/search-keymaps.vim の rtp+= で対応済みのため、ここでは Windows 分のみ追加する
set rtp+=~/AppData/Local/nvim/pack/plugins/start/fzf

" C-h/C-l でウィンドウ移動（GitBash/zellij 環境ではプラグインでのウィンドウ移動が使えないため）
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" zellij 環境対応: ペイン移動に Ctrl を使うため、fzf のスプリット操作は Alt に変更する
" (vimrc.d/search-keymaps.vim の既定は ctrl-x/ctrl-v)
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'alt-h': 'split',
  \ 'alt-v': 'vsplit' }

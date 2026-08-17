" GitBash (Windows) 特有の設定
" _vimrc から source される。vim/nvim 共通。

" ファイルパスを GitBash 形式（C:\... → /c/...）へ変換してクリップボード（clip）へコピーし、
" 変換後のパスを返す。_vimrc の CopyFilePath() から Windows 環境でのみ呼ばれる。
function! GitBashCopyPath(path) abort
  let l:copy_path = substitute(a:path, '^\([A-Za-z]\):', '/\L\1', '')
  let l:copy_path = substitute(l:copy_path, '\\', '/', 'g')
  call system('printf "%s" "' . l:copy_path . '" | clip')
  return l:copy_path
endfunction

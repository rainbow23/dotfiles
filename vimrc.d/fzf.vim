" fzf ベースの検索実装
" キーマップは vimrc.d/search-keymaps.vim で一元管理する
" nvim で telescope 実装（nvim/lua/rc/）に置き換え済みのコマンドは !has('nvim') で無効化する

" 両環境共通: fzf 版 Files（プレビュー付き）
command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview('right:50%:hidden', '?'), <bang>0)

function! s:rg_raw(command_suffix, ...)
  if !executable('rg')
    return s:warn('rg is not found')
  endif
  let s:cmd='rg --column --line-number --no-heading --color=always --smart-case -- ' .
    \ a:command_suffix
  return call('fzf#vim#grep', extend([s:cmd, 1], a:000))
endfunction

function! s:rg(query, ...)
  let query = empty(a:query) ? '' : a:query
  let args  = copy(a:000)
  " echo a:000 >> [{'options': '', 'dir': '/Users/goodscientist1023/dotfiles', 'down': '~30%'}]
  return call('s:rg_raw', insert(args, fzf#shellescape(query), 0))
endfunction

" Plug 'svermeulen/vim-easyclip' ##################################################
" クリップボードにコピーしたものを履歴として残す。vim再起動時に復元
" pastetoggle は nvim で廃止されたため無効化
let g:EasyClipUseGlobalPasteToggle = 0
let g:EasyClipShareYanks = 1

" easycilpからコピーした一覧を取得
function! s:yank_list()
  redir => ys
  silent Yanks
  redir END
  return split(ys, '\n')[1:]
endfunction

" 引数からPasteコマンドで貼り付け
function! s:yank_handler(reg)
  if empty(a:reg)
    echo "aborted register paste"
  else
    let token = split(a:reg, ' ')
    execute 'Paste' . token[0]
  endif
endfunction

" fzfを使って一覧を呼び出して貼り付け
command! FZFYank call fzf#run({
\ 'source': <sid>yank_list(),
\ 'sink': function('<sid>yank_handler'),
\ 'options': '-m --prompt="FZFYank> "',
\ 'down':    '40%'
\ })
" Plug 'svermeulen/vim-easyclip' ##################################################

" ここから下は plain vim 専用（nvim は telescope 版が同名コマンドを定義する）
if has('nvim')
  finish
endif

function! s:FzfSessionLoad(name)
  let l:path = glob(expand('~/.vim/sessions/') . a:name)
  if l:path != ''
    execute 'source ' . fnameescape(l:path)
    echo 'Session loaded: ' . fnamemodify(a:name, ':r')
  else
    echo 'Session file not found: ' . a:name
  endif
endfunction

command! MySessionLoad call fzf#run(fzf#wrap({
      \ 'source': map(split(glob(expand('~/.vim/sessions/') . '*.vim'), '\n'), 'fnamemodify(v:val, ":t")'),
      \ 'sink': function('<sid>FzfSessionLoad'),
      \ 'options': '--prompt "Sessions> " --header "CR=ロード"',
      \ 'down': '40%'}))

command! -bang -nargs=* FZFMru call fzf#vim#history(fzf#vim#with_preview('right:50%:hidden', '?'))

 " Make Ripgrep ONLY search file contents and not filenames
command! -bang -nargs=* GrepSearch
  \ call fzf#vim#grep(
  \   'rg --column --line-number --hidden --smart-case -g !.git/ --no-heading --color=always ^ $(git rev-parse --show-toplevel) '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
  \           : fzf#vim#with_preview({'options': '--delimiter : --nth 4.. -e'}, 'right:30%', '?'),
  \   <bang>0)

command! -bang -nargs=* SearchFromCurrDir
  \ call fzf#vim#grep(
  \   'rg --column --line-number --hidden --smart-case --no-heading --color=always ^ $(pwd) '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
  \           : fzf#vim#with_preview({'options': '--delimiter : --nth 4.. -e'}, 'right:30%', '?'),
  \   <bang>0)

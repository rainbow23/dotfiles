" 検索系（fzf / telescope）の一元管理: キーマップと共通設定
" ここにはキーマップとコマンド名のインターフェースのみを置き、実装は環境ごとに定義する
"   nvim → nvim/lua/rc/search.lua, rc/session.lua（telescope 実装）
"   vim  → vimrc.d/fzf.vim（fzf.vim 実装）

" fzf 共通設定
if has("mac")
    set rtp+=~/.fzf
elseif has("unix")
    set rtp+=~/.fzf
endif

let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" fzfからファイルにジャンプできるようにする
let g:fzf_buffers_jump = 1

" nvim のターミナルモードで Esc がfzfに届かない問題の対策
let $FZF_DEFAULT_OPTS = '--bind esc:abort'
if has('nvim')
  autocmd! FileType fzf tnoremap <buffer> <Esc> <Esc>
endif

let g:fzf_layout = { 'down': '~30%' }

" batの代わりにcatを使用（パフォーマンス検証用）
let $FZF_PREVIEW_COMMAND = 'cat {}'

" 検索系キーマップ（呼び出すコマンドの実装は環境別ファイルを参照）
nnoremap [fzf] <Nop>
nmap <Leader>f [fzf]

nnoremap [fzf]us :<C-u>MySessionLoad<CR>
nnoremap [fzf]m :<C-u>FZFMru<CR>
nnoremap [fzf]f :<C-u>FileSearch<CR>
nnoremap [fzf]g :<C-u>GitStatus<CR>
nnoremap [fzf]b :<C-u>MyBuffersMemos<CR>
nnoremap [fzf]h :<C-u>History<CR>
" list tabs
nnoremap [fzf]w :<C-u>Windows<CR>
nnoremap [fzf]l :<C-u>BLines<CR>
nnoremap [fzf]s :<C-u>GrepSearch<CR>
nnoremap [fzf]S :<C-u>FileSearchFromCurrDir<CR>
nnoremap [fzf]y :<C-U>FZFYank<CR>
inoremap [fzf]y <C-O>:<C-U>FZFYank<CR>

" Mapping selecting mappings
nmap <leader><tab> <plug>(fzf-maps-n)
xmap <leader><tab> <plug>(fzf-maps-x)
omap <leader><tab> <plug>(fzf-maps-o)
" Insert mode completion
" imap <c-x><c-k> <plug>(fzf-complete-word)
imap <c-x><c-f> <plug>(fzf-complete-path)
imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)
" Advanced customization using autoload functions
" inoremap <expr> <c-x><c-k> fzf#vim#complete#word({'left': '15%'})

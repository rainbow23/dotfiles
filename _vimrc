set number
set showmatch
set matchtime=1
set autoindent
set shiftwidth=4
set tabstop=4
syntax on
set hlsearch
autocmd InsertLeave * set nopaste
"ヤンクをクリップボードに保存　kana/vim-fakeclipと連動
set clipboard=unnamed
"set termguicolors nvim用
"set nohlsearch
"set cursorline
"highlight Normal ctermbg=black ctermfg=white
highlight StatusLine term=none cterm=none ctermfg=black ctermbg=grey
"highlight CursorLine term=none cterm=none ctermfg=none ctermbg=grey

call plug#begin('~/.vim/plugged') 
Plug 'junegunn/vim-easy-align'
"Plug 'powerline/fonts'
Plug 'Shougo/unite.vim'
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'
Plug 'Shougo/neocomplcache.vim'
Plug 'Shougo/unite-session'
Plug 'Shougo/neomru.vim'
"unite-outline brew install ctagsが必要
Plug 'Shougo/unite-outline'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'kana/vim-fakeclip'
Plug 'terryma/vim-multiple-cursors'
call plug#end()

"EasyAlign start ####################################################################
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
"EasyAlign end  #####################################################################

"vim-airline start ##################################################################
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme='badwolf'
let g:airline#extensions#syntastic#enabled = 1
"let g:airline#extensions#tabline#left_sep = ' '
"let g:airline#extensions#tabline#left_alt_sep = '|'
set laststatus=2
set t_Co=256 "vim-air-line-themeを反映させる
"vim-airline end  #####################################################################

"nnoremap <C-N> :bnext<CR>
"nnoremap <C-P> :bprevious<CR>
nnoremap <C-X> :bdelete<CR>
nmap <Leader>b :CtrlPBuffer<CR>
nnoremap <C-H> :noh <CR>
" x:削除でヤンクしない
nnoremap x "_x
nnoremap dd "_dd
nnoremap dw "_dw

"改行後INSERT MODEにしない
nnoremap O :<C-u>call append(expand('.'), '')<Cr>j
"nnoremap O o<Esc>

"ノーマルモード＋ビジュアルモード
noremap <C-j> <Esc>
"コマンドラインモード＋インサートモード
noremap! <C-j> <Esc>

"neosnippets start #################################################################
imap <C-l>     <plug>(neosnippet_expand_or_jump)
smap <C-l>     <plug>(neosnippet_expand_or_jump)
xmap <C-l>     <plug>(neosnippet_expand_target)
let g:neosnippet#snippets_directory='~/.vim/plugged/neosnippet-snippets/neosnippets'
map <C-l>     <Plug>(neosnippet_expand_or_jump)
"SuperTab like snippets behavior.
imap  <expr><TAB>
     \ pumvisible() ? "\<C-n>" :
     \ neosnippet#expandable_or_jumpable() ?
     \ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
	\ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

if has('conceal')
 set conceallevel=2 concealcursor=i
endif
"neosnippets end ###################################################################

"neocomplcache start ###############################################################
highlight Pmenu ctermbg=6
highlight PmenuSel ctermbg=3
highlight PMenuSbar ctermbg=0

let g:neocomplcache_enable_at_startup = 1
let g:neocomplcache_max_list = 30
let g:neocomplcache_auto_completion_start_length = 2
let g:neocomplcache_enable_smart_case = 1
"" like AutoComplPop
let g:neocomplcache_enable_auto_select = 1
"" search with camel case like Eclipse
let g:neocomplcache_enable_camel_case_completion = 1
let g:neocomplcache_enable_underbar_completion = 1
"imap <C-k> <Plug>(neocomplcache_snippets_expand)
"smap <C-k> <Plug>(neocomplcache_snippets_expand)
inoremap <expr><C-g> neocomplcache#undo_completion()
"inoremap <expr><C-l> neocomplcache#complete_common_string()

"" SuperTab like snippets behavior.
"imap <expr><TAB> neocomplcache#sources#snippets_complete#expandable() ? "\<Plug>(neocomplcache_snippets_expand)" : pumvisible() ? "\<C-n>" : "\<TAB>"
"" <CR>: close popup and save indent.
"inoremap <expr><CR> neocomplcache#smart_close_popup() . (&indentexpr != '' ? "\<C-f>\<CR>X\<BS>":"\<CR>")
inoremap <expr><CR> pumvisible() ? neocomplcache#close_popup() : "\<CR>"
"" <TAB>: completion.
"inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
"" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplcache#smart_close_popup() . "\<C-h>"
inoremap <expr><BS> neocomplcache#smart_close_popup() . "\<C-h>"
inoremap <expr><C-y> neocomplcache#close_popup()
inoremap <expr><C-e> neocomplcache#cancel_popup()
"neocomplcache end ############################################################

"unite start ##################################################################
"インサートモードで開始
"let g:unite_enable_start_insert=1
"ヒストリー/ヤンク機能を有効化
let g:unite_source_history_yank_enable =1
"prefix keyの設定
nmap     <Space> [unite]

"今開いているファイルに適応 start  ###############################
"ファイル一覧を表示する
nnoremap <silent> [unite]f    :<C-u>UniteWithBufferDir -buffer-name=files file <CR>
"最近使ったファイルの一覧を表示
nnoremap <silent> [unite]<CR> :<C-u>UniteWithBufferDir file_mru<CR>
"今開いているファイルに適応 end    ###############################

"現在位置のファイルの一覧を表示
nnoremap <silent> [unite]c :<C-u>Unite file_rec:!<CR>
"最近使ったファイルの一覧を表示 MostRecentUse
nnoremap <silent> [unite]m :<C-u>Unite file_mru<CR>

"セッションを保存 start   ##
:command! -nargs=? Uss call s:Unite_session_save(<f-args>)
:function! s:Unite_session_save(...)
: if a:0 >= 1
:	let hogearg = a:1
:	echo "UniteSessionSave ".hogearg
:	execute 'UniteSessionSave ' . a:1
: else
:   echo "UniteSessionSave default"
":  echo "noarg!"
:   execute 'UniteSessionSave default'
: end
:endfunction
"セッションを保存 enc    ##

"全体に適応 start  ###############################################
"nnoremap <silent> [unite]d :<C-u>Unite directory_mru<CR>
nnoremap <silent> [unite]b :<C-u>Unite buffer<CR>
nnoremap <silent> [unite]s :<C-u>Unite session<CR>
nnoremap <silent> [unite]t :<C-u>Unite tab<CR>
"スペースキーとrキーでレジストリを表示
nnoremap <silent> [unite]r :<C-u>Unite register<CR>
"全体に適応 end    ###############################################

"unite.vimを開いている間のキーマッピング
autocmd FileType unite call s:unite_my_settings()
function! s:unite_my_settings()"{{{
    " ESCでuniteを終了
    nmap <buffer> <ESC> <Plug>(unite_exit)
	"入力モードのときjjでノーマルモードに移動
	"map <buffer> jj <Plug>(unite_insert_leave)

	"入力モードのときctrl+wでバックスラッシュも削除
	imap <buffer> <c-w> <plug>(unite_delete_backward_path)

	"横に分割して開く
	nnoremap <silent> <buffer> <expr> <C-t> unite#do_action('split')
	inoremap <silent> <buffer> <expr> <C-t> unite#do_action('split')

	"縦に分割して開く
	nnoremap <silent> <buffer> <expr> <C-v> unite#do_action('vsplit')
	inoremap <silent> <buffer> <expr> <C-v> unite#do_action('vsplit')
	"ctrl+oでその場所に開く
	nnoremap <silent> <buffer> <expr> <C-o> unite#do_action('open')
	inoremap <silent> <buffer> <expr> <C-o> unite#do_action('open')

	nmap <buffer> <C-j> <Plug>(unite_exit)
endfunction"}}}
"unite end #####################################################################

"unite out-line start ##########################################################
:command! -nargs=? Uo call s:Unite_outline(<f-args>)
:function! s:Unite_outline(...)
: if a:0 >= 1
:	let hogearg = a:1
:	execute 'Unite -winheight=' . a:1.' outline'
: else
:   echo "Unite outline"
:	execute "Unite -winheight=10 outline"
: end
:endfunction
"unite out-line end   ##########################################################

"vim-multiple-cursors start ####################################################
"prefix keyの設定
let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_next_key='<C-n>'
let g:multi_cursor_prev_key='<C-p>'
let g:multi_cursor_skip_key='<C-x>'
let g:multi_cursor_quit_key='<Esc>'
let g:multi_cursor_start_key='<C-n>'
let g:multi_cursor_start_word_key='g<C-n>'
"vim-multiple-cursors end ######################################################

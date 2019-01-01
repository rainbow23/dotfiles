set backspace=indent,eol,start
set number
set matchtime=1
set autoindent
set shiftwidth=4
set tabstop=4
set noswapfile
set ignorecase
set noshowmode
"set tags=./tags;
" 開いたファイルにワーキングディレクトリを移動する
if 1 == exists("+autochdir")
    set autochdir
endif
syntax on
colorscheme peachpuff
filetype on
set hlsearch

set encoding=utf-8

autocmd BufEnter *.yml set shiftwidth=2
autocmd BufEnter *.sh  set shiftwidth=2
autocmd BufEnter *.zsh set shiftwidth=2
autocmd BufEnter *.vimrc set shiftwidth=2
autocmd InsertLeave * set nopaste

" autocmd BufRead * if getfsize(expand(@%)) == -1 | :q | endif

"ヤンクをクリップボードに保存　kana/vim-fakeclipと連動
set clipboard=unnamed
" タブ入力を複数の空白入力に置き換える
set expandtab
" 画面上でタブ文字が占める幅
set tabstop=4

let mapleader = "\<Space>"
"let mapleader = ","

"カーソル位置から画面移動
nnoremap .t zt
nnoremap .m zz
nnoremap .b zb

nnoremap sn :<C-u>set number<CR>
nnoremap snn :<C-u>set nonumber<CR>

nnoremap <silent> uss :<C-u>Uss<CR>
nnoremap <silent> usos :call <SID>Unite_session_override_save()<CR>
nnoremap src :<C-u>source ~/.vimrc<CR>
nnoremap setp :<C-u>set paste<CR>
nnoremap tn :tabnew<CR>
nnoremap tk :tabnext<CR>
nnoremap tj :tabprev<CR>
nnoremap th :tabfirst<CR>
nnoremap tl :tablast<CR>

nnoremap tmk :tabmove +1<CR>
nnoremap tmj :tabmove -1<CR>

" 現在開いているファイルにワーキングディレクトリを移動する
nnoremap mvd :<C-u>cd %:h<CR> :pwd<CR>
" fullpathでファイル名表示
nnoremap <C-G> :echo expand('%:p') <CR>
nnoremap <Leader>pj :echo cfi#format("%s", "")<CR>
nnoremap <Leader>p :echo expand('%:p') <CR>

nnoremap [buffer]    <Nop>
nmap     <Leader>b [buffer]
nnoremap [buffer]p :bprevious<CR>
nnoremap [buffer]n :bnext<CR>
"前に開いたファイルを開く
nnoremap [buffer]r :b#<CR>
"直前のバッファを開く
nnoremap [buffer]d :bdelete<CR>

" panel size start ################################
nnoremap noremap [panel]    <Nop>
nmap     s [panel]
nnoremap [panel]hh  :vertical resize -10<CR>
nnoremap [panel]hhh :vertical resize -40<CR>
" 横に最小化
nnoremap [panel]hhhh <C-w>1\| <C-g><CR>
nnoremap [panel]ll  :vertical resize +10<CR>
nnoremap [panel]lll :vertical resize +40<CR>
" 横に最大化
nnoremap [panel]jj  :resize +10<CR>
nnoremap [panel]jjj :resize +20<CR>
" 縦に最大化
nnoremap [panel]kk  :resize -10<CR>
nnoremap [panel]kkk :resize -20<CR>
" 縦に最小化
nnoremap [panel]kkkk <C-w>1_ <C-g><CR>
nnoremap [panel]l <C-w>l <C-g><CR>
nnoremap [panel]h <C-w>h <C-g><CR>
nnoremap [panel]j <C-w>j <C-g><CR>
nnoremap [panel]k <C-w>k <C-g><CR>
nnoremap [panel]w <C-w>w <C-g><CR>
nnoremap [panel]s :split <C-g><CR>
nnoremap [panel]v :vsplit <C-g><CR>
nnoremap [panel]H <C-w>H <C-g><CR>
nnoremap [panel]J <C-w>J <C-g><CR>
nnoremap [panel]K <C-w>K <C-g><CR>
nnoremap [panel]L <C-w>L <C-g><CR>
" 上向きにローテーションする
nnoremap [panel]r <C-w>r <C-g><CR>
" 下向きにローテーションする
nnoremap [panel]R <C-w>R <C-g><CR>
" 現在カーソルがあるウィンドウと一つ前のウィンドウを入れ替える
nnoremap [panel]x <C-w>x <C-g><CR>
noremap [panel]o <C-w>= <C-g><CR>


" let g:tmux_navigator_no_mappings = 1
" nnoremap <silent> [panel]h :TmuxNavigateLeft<cr>
" nnoremap <silent> [panel]j :TmuxNavigateDown<cr>
" nnoremap <silent> [panel]k :TmuxNavigateUp<cr>
" nnoremap <silent> [panel]l :TmuxNavigateRight<cr>
" nnoremap <silent> [panel]p :TmuxNavigatePrevious<cr>


" panel size end  #################################

" Plug 'regedarek/ZoomWin' ###########################################################################
" 選択したパネルの最大化
" nnoremap <silent> [panel]wo :call <SID>MyZoomWin()<CR>
nnoremap <silent> [panel]wo :<C-u>ZoomWin<CR>

set stl=Normal
let g:zoomWinActive = 0

fun! s:MyZoomWin()
    if g:zoomWinActive == 1
      " :TagbarClose
      let g:zoomWinActive = 0
    endif
    :ZoomWin
endfun

" ZoomWin()の後に呼ばれる
fun! ZWStatline(state)
  if a:state
    let g:zoomWinActive = 1
    " Unite session loadでレイアウトが崩れる場合があるので今はtagbarを開かない
    " :TagbarOpen
    set stl=ZoomWin
  else
    set stl=Normal
  endif
endfun

if !exists("g:ZoomWin_funcref")
  let g:ZoomWin_funcref= function("ZWStatline")
endif
" Plug 'regedarek/ZoomWin' ###########################################################################

if has('nvim')
" removed 'key', 'oft', 'sn', 'tx' options which do not work with nvim
let g:zoomwin_localoptlist = ["ai","ar","bh","bin","bl","bomb","bt","cfu","ci","cin","cink","cino","cinw","cms","com","cpt","diff","efm","eol","ep","et","fenc","fex","ff","flp","fo","ft","gp","imi","ims","inde","inex","indk","inf","isk","kmp","lisp","mps","ml","ma","mod","nf","ofu","pi","qe","ro","sw","si","sts","spc","spf","spl","sua","swf","smc","syn","ts","tw","udf","wfh","wfw","wm"]
endif
" Plug 'regedarek/ZoomWin' ###########################################################################


nnoremap <C-H> :noh <CR>
" 削除でヤンクしない
nnoremap x "_x
nnoremap dd "_dd
nnoremap dw "_dw
nnoremap d$ "_d$
nnoremap diw "_diw

nnoremap ; :
nnoremap : ;
nnoremap 88 *

"改行後INSERT MODEにしない
nnoremap O :<C-u>call append(expand('.'), '')<Cr>j
"検索ハイライトを消す
nnoremap ns :<C-u>nohlsearch<CR>

"進む 一行
nnoremap <silent> <C-e> <C-e>j
"進む 画面半分
nnoremap <silent> <C-d> <C-d>zz
"10行進む
nnoremap <Leader>j 10<C-e>10j
"進む 画面1ページ分
nnoremap <silent> <C-f> <C-f>zz
"戻る 一行
nnoremap <silent> <C-y> <C-y>k
"10行戻る
nnoremap <Leader>k 10<C-y>10k
"戻る 画面半分
nnoremap <silent> <C-u> <C-u>zz
"戻る 画面1ページ分
nnoremap <silent> <C-b> <C-b>zz

" インサートモード
inoremap <silent> jj <ESC>l

"set termguicolors nvim用
"set nohlsearch
"set cursorline
"highlight Normal ctermbg=black ctermfg=white
highlight StatusLine term=none cterm=none ctermfg=black ctermbg=grey
"highlight CursorLine term=none cterm=none ctermfg=none ctermbg=grey
nnoremap <Leader>. :<C-u>tabedit $MYVIMRC<CR>
:set list lcs=tab:\|\ 


if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'junegunn/vim-easy-align'
Plug 'junegunn/fzf.vim'
"Plug 'powerline/fonts'
Plug 'Shougo/unite.vim'
Plug 'rainbow23/unite-session'
Plug 'Shougo/neomru.vim'
Plug 'Shougo/vimfiler.vim'
"unite-outline brew install ctagsが必要
Plug 'Shougo/unite-outline'
Plug 'Shougo/vimproc.vim', {'do' : 'make'}
Plug 'Shougo/deol.nvim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'kana/vim-fakeclip'
Plug 'terryma/vim-multiple-cursors'
Plug 'thinca/vim-quickrun'
Plug 'osyo-manga/unite-quickfix'
Plug 'osyo-manga/shabadou.vim'
Plug 'Yggdroot/indentLine'
Plug 'ctrlpvim/ctrlp.vim'
"Plug 'cohama/lexima.vim'
Plug 'rainbow23/vim-anzu'
Plug 'majutsushi/tagbar'
Plug 'rhysd/clever-f.vim'
Plug 'MattesGroeger/vim-bookmarks'
Plug 'ivalkeen/vim-ctrlp-tjump'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'soramugi/auto-ctags.vim'
Plug 'airblade/vim-gitgutter'
" Plug 'deris/vim-gothrough-jk'
Plug 'rhysd/accelerated-jk'
Plug 'easymotion/vim-easymotion'
Plug 'elzr/vim-json'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'vim-syntastic/syntastic'
" Plug 'Townk/vim-autoclose' vim-multiple-cursorsに不具合
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
"exmodeから確認  call deoplete#enable()
if has("mac")

elseif has("unix")
    let g:python3_host_prog = expand('/usr/local/bin/python3.5')
endif

if has('pythonx')
    set pyxversion=3
endif
if has('python3')
:python3 import neovim
endif
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'
Plug 'padawan-php/deoplete-padawan', { 'do': 'composer install' }
Plug 'zchee/deoplete-go', { 'do': 'make'}
Plug 'fatih/vim-go'
Plug 'Shougo/neco-syntax'
Plug 'machakann/vim-sandwich'
Plug 'ntpeters/vim-better-whitespace'
Plug 'tyru/current-func-info.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'regedarek/ZoomWin'
Plug 'leafcage/yankround.vim'
Plug 'ujihisa/unite-colorscheme'
Plug 'christoomey/vim-tmux-navigator'
call plug#end()

function! s:all_files()
  return extend(
  \ filter(copy(v:oldfiles),
  \        "v:val !~ 'fugitive:\\|NERD_tree\\|^/tmp/\\|.git/'"),
  \ map(filter(range(1, bufnr('$')), 'buflisted(v:val)'), 'bufname(v:val)'))
endfunction

"FZF start ####################################################################
if has("mac")
    set rtp+=/usr/local/opt/fzf
elseif has("unix")
    set rtp+=~/.fzf
endif

let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

nnoremap [fzf] <Nop>
nmap <Leader>f [fzf]

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

nnoremap [fzf]m :<C-u>FZFMru<CR>
nnoremap [fzf]f :<C-u>Files<CR>
" git ls-files
nnoremap [fzf]g :<C-u>GFiles<CR>
" git staus
nnoremap [fzf]G :<C-u>GFiles?<CR>
nnoremap [fzf]b :<C-u>Buffers<CR>
nnoremap [fzf]h :<C-u>History<CR>
" list tabs
nnoremap [fzf]w :<C-u>Windows<CR>
nnoremap [fzf]a :<C-u>Ag<CR>
nnoremap [fzf]l :<C-u>Lines<CR>
nnoremap [fzf]s :<C-u>Search<CR>
nnoremap [fzf]S :<C-u>SearchFromCurrDir<CR>

command! -bang -nargs=* FZFMru call fzf#vim#history(fzf#vim#with_preview())

command! -bang -nargs=? GFiles
\ call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview(), <bang>0),

command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

command! -bang -nargs=* Search
  \ call fzf#vim#grep(
  \   'ag --nogroup --column --nocolor ^ $(git rev-parse --show-toplevel main)', 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:hidden', '?'),
  \   <bang>0)

command! -bang -nargs=* SearchFromCurrDir
  \ call fzf#vim#grep(
  \   'ag --nogroup --column --nocolor ^ $(pwd)', 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:hidden', '?'),
  \   <bang>0)

command! -bang -nargs=* Ag
  \ call fzf#vim#ag(<q-args>,
  \                 <bang>0 ? fzf#vim#with_preview('up:60%')
  \                         : fzf#vim#with_preview('right:50%:hidden', '?'),
  \                 <bang>0)
"FZF end  ####################################################################

"EasyAlign start ####################################################################
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
"EasyAlign end  #####################################################################

"vim-airline start ##################################################################
let g:airline#extensions#tabline#enabled = 1
" タブに表示する名前（fnamemodifyの第二引数）
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline_powerline_fonts = 1
let g:airline_theme='badwolf'
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
set laststatus=2
set t_Co=256 "vim-air-line-themeを反映させる
"vim-airline end  #####################################################################

"neosnippets start #################################################################
" Plugin key-mappings.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)

" SuperTab like snippets behavior.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
"imap <expr><TAB>
" \ pumvisible() ? "\<C-n>" :
" \ neosnippet#expandable_or_jumpable() ?
" \    "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

" For conceal markers.
if has('conceal')
  set conceallevel=2 concealcursor=niv
endif
"neosnippets end ###################################################################

" deoplete start ###################################################################
let g:deoplete#enable_at_startup = 1
let g:deoplete#sources#go#sort_class = ['package', 'func', 'type', 'var', 'const']

"ノーマルモード＋ビジュアルモード
noremap <C-j> <Esc>
"コマンドラインモード＋インサートモード
noremap! <C-j> <Esc>

" <CR>: close popup.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
inoremap <silent> <C-j> <C-r>=<SID>my_cj_function()<CR>

function! s:my_cr_function()
    return pumvisible() ? deoplete#mappings#close_popup() : "\n"
endfunction

function! s:my_cj_function()
    return pumvisible() ? deoplete#mappings#close_popup() : ""
endfunction

inoremap <silent><expr> <TAB>
\ pumvisible() ? "\<C-n>" :
\ <SID>check_back_space() ? "\<TAB>" :
\ deoplete#mappings#manual_complete()

function! s:check_back_space() abort "{{{
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~ '\s'
endfunction"}}}
" deoplete end #####################################################################

"neocomplcache start ###############################################################
" highlight Pmenu ctermbg=6
" highlight PmenuSel ctermbg=3
" highlight PMenuSbar ctermbg=0

" let g:neocomplcache_enable_at_startup = 1
" let g:neocomplcache_max_list = 30
" let g:neocomplcache_auto_completion_start_length = 2
" let g:neocomplcache_enable_smart_case = 1
" "" like AutoComplPop
" let g:neocomplcache_enable_auto_select = 1
" "" search with camel case like Eclipse
" let g:neocomplcache_enable_camel_case_completion = 1
" let g:neocomplcache_enable_underbar_completion = 1
" "imap <C-k> <Plug>(neocomplcache_snippets_expand)
" "smap <C-k> <Plug>(neocomplcache_snippets_expand)
" inoremap <expr><C-g> neocomplcache#undo_completion()
" "inoremap <expr><C-l> neocomplcache#complete_common_string()

" "" SuperTab like snippets behavior.
" "imap <expr><TAB> neocomplcache#sources#snippets_complete#expandable() ? "\<Plug>(neocomplcache_snippets_expand)" : pumvisible() ? "\<C-n>" : "\<TAB>"
" "" <CR>: close popup and save indent.
" "inoremap <expr><CR> neocomplcache#smart_close_popup() . (&indentexpr != '' ? "\<C-f>\<CR>X\<BS>":"\<CR>")
" inoremap <expr><CR> pumvisible() ? neocomplcache#close_popup() : "\<CR>"
" "" <TAB>: completion.
" "inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
" "" <C-h>, <BS>: close popup and delete backword char.
" inoremap <expr><C-h> neocomplcache#smart_close_popup() . "\<C-h>"
" inoremap <expr><BS> neocomplcache#smart_close_popup() . "\<C-h>"
" inoremap <expr><C-y> neocomplcache#close_popup()
" inoremap <expr><C-e> neocomplcache#cancel_popup()
"neocomplcache end ############################################################

"unite start ##################################################################
let g:unite_data_directory = expand('~/.vim/etc/unite')
"ヒストリー/ヤンク機能を有効化
let g:unite_source_history_yank_enable =1
" 大文字小文字を区別しない
let g:unite_enable_ignore_case = 1
let g:unite_enable_smart_case = 1

if (glob('~/.vim/plugged/unite.vim'))
    call unite#custom#profile('default', 'context', {
     \ 'split' : 1,
     \ 'start_insert': 0,
     \ 'vertical_preview': 1,
     \ 'toggle' : 1,
     \ })
endif

"prefix keyの設定
nnoremap [unite]    <Nop>
nmap     <Leader>u [unite]

"今開いているファイルに適応 start  ##################
"ファイル一覧を表示する
nnoremap <silent> [unite]f    :<C-u>UniteWithBufferDir -buffer-name=files file <CR>
"最近使ったファイルの一覧を表示
nnoremap <silent> [unite]<CR> :<C-u>UniteWithBufferDir file_mru<CR>
"今開いているファイルに適応 end    ##################

"現在位置のファイルの一覧を表示
nnoremap <silent> [unite]c :<C-u>Unite file_rec:!<CR>
"最近使ったファイルの一覧を表示 MostRecentUse
nnoremap <silent> [unite]m :<C-u>Unite file_mru<CR>

"全体に適応 start  ###########
nnoremap <silent> [unite]d :<C-u>Unite directory_mru<CR>
nnoremap <silent> [unite]b :<C-u>Unite -auto-resize buffer<CR>
nnoremap <silent> [unite]s :<C-u>Unite -auto-resize session<CR>
nnoremap <silent> us :<C-u>Unite -auto-resize session<CR>
nnoremap <silent> [unite]t :<C-u>Unite -auto-resize tab<CR>
nnoremap <silent> ta :<C-u>Unite -auto-resize tab<CR>
nnoremap <silent> ut :<C-u>Unite -auto-resize tab<CR>
"スペースキーとrキーでレジストリを表示
nnoremap <silent> [unite]r :<C-u>Unite register<CR>
nnoremap <silent> [unite]v :<C-u>VimFiler -buffer-name=default -split -simple -winwidth=35 -toggle -no-quit<CR>
nnoremap <silent> uo :<C-u>Unite -auto-resize outline<CR>
nnoremap <silent> uov :<C-u>Unite -vertical -winwidth=50 outline<CR>
nnoremap <silent> uv :<C-u>Unite -auto-resize output:version<CR>

"MattesGroeger/vim-bookmarks ***********************************************
highlight BookmarkLine ctermbg=238 ctermfg=none
highlight BookmarkAnnotationLine ctermbg=238 ctermfg=none
let g:bookmark_highlight_lines = 1

nnoremap <silent> [unite]kk :<C-u>Unite -auto-resize vim_bookmarks<CR>
"Unite bookmarkを開く
nnoremap <silent> [unite]k  :<C-u>Unite -auto-resize bookmark<CR>
"Uniteのbookmarkに追加 ~/.unite/bookmark/default に格納
nnoremap <silent> [unite]ab :<C-u>UniteBookmarkAdd<CR>
" grep検索
nnoremap <silent> [unite]g  :<C-u>Unite grep:. -buffer-name=search-buffer<CR>
" カーソル位置の単語をgrep検索
nnoremap <silent> [unite]cg :<C-u>Unite grep:. -buffer-name=search-buffer<CR><C-R><C-W>
" grep検索結果の再呼出
nnoremap <silent> [unite]r  :<C-u>UniteResume search-buffer<CR>
" unite grep に ag(The Silver Searcher) を使う
if executable('ag')
  let g:unite_source_grep_command = 'ag'
  let g:unite_source_grep_default_opts = '--nogroup --nocolor --column'
  let g:unite_source_grep_recursive_opt = ''
endif
"全体に適応 end    ##########

"vimfiler ##################
"vimデフォルトのエクスプローラをvimfilerで置き換える
let g:vimfiler_as_default_explorer = 1
"セーフモードを無効にした状態で起動する
let g:vimfiler_safe_mode_by_default = 0

"autocmd VimEnter * VimFilerExplorer
" autocmd FileType vimfiler nmap <buffer> <Leader>uv <Plug>(vimfiler_close)

augroup vimrc
    autocmd FileType vimfiler call s:vimfiler_my_settings()
augroup END

function! s:vimfiler_my_settings()
echo 'vimfiler_my_settings'
let loaded_trailing_whitespace_plugin = 0
    nmap <buffer> q <Plug>(vimfiler_close)
    nmap <buffer> Q <Plug>(vimfiler_hide)
"横に分割して開く
    nnoremap <silent> <buffer> <expr> <C-s> vimfiler#do_switch_action('split')
    inoremap <silent> <buffer> <expr> <C-s> vimfiler#do_switch_action('split')
    nnoremap <silent> <buffer> <expr> <C-h> vimfiler#do_switch_action('split')
    inoremap <silent> <buffer> <expr> <C-h> vimfiler#do_switch_action('split')
"縦に分割して開く
    nnoremap <silent> <buffer> <expr> <C-v> vimfiler#do_switch_action('vsplit')
    inoremap <silent> <buffer> <expr> <C-v> vimfiler#do_switch_action('vsplit')
"タブで開く
    nnoremap <silent> <buffer> <expr> <C-t> vimfiler#do_action('tabopen')
    nnoremap <silent> <buffer> <expr> <C-t> vimfiler#do_action('tabopen')
endfunction
"vimfiler ##################

"セッションを保存 start   ##
let g:unite_source_session_default_session_name = 'default'

command! -nargs=? Uss call s:Unite_session_save(<f-args>)
function! s:Unite_session_save(...)
    NERDTreeTabsClose
    TagbarClose
    if a:0 >= 1
        let hogearg = a:1
        echo "UniteSessionSave ".hogearg
        execute 'UniteSessionSave ' . a:1
    else
        echo "UniteSessionSave ".g:unite_source_session_default_session_name
        execute 'UniteSessionSave '.g:unite_source_session_default_session_name
    end
    NERDTreeTabsOpen
endfunction
"セッションを保存 enc    ##

"セッションを上書き保存
function! s:Unite_session_override_save()
   let filepath = v:this_session
    if filepath  == ''
        let filepath = g:unite_source_session_default_session_name
    endif

   let filename = fnamemodify(filepath, ":t:r")
   let inputtext = input("save current session? "."session_name=".filename." y or n ")
      redraw
   if inputtext == 'y'
      NERDTreeTabsClose
      TagbarClose
      echo "UniteSessionSave ".filename
      execute 'UniteSessionSave ' .filename
   else
      echo "canceled save current session. session_name=".filename
   endif
endfunction

"unite.vimを開いている間のキーマッピング
autocmd FileType unite call s:unite_my_settings()
function! s:unite_my_settings()"{{{
set number
    " ESCでuniteを終了
    nmap <buffer> <ESC> <Plug>(unite_exit)
    nmap <buffer> <C-j> <Plug>(unite_exit)
    nmap <buffer> q     <Plug>(unite_exit)

    "入力モードのときjjでノーマルモードに移動
    "map <buffer> jj <Plug>(unite_insert_leave)

    "入力モードのときctrl+wでバックスラッシュも削除
    imap <buffer> <c-w> <plug>(unite_delete_backward_path)

    "横に分割して開く
    nnoremap <silent> <buffer> <expr> <C-s> unite#do_action('split')
    inoremap <silent> <buffer> <expr> <C-s> unite#do_action('split')
    nnoremap <silent> <buffer> <expr> <C-h> unite#do_action('split')
    inoremap <silent> <buffer> <expr> <C-h> unite#do_action('split')

    "縦に分割して開く
    nnoremap <silent> <buffer> <expr> <C-v> unite#do_action('vsplit')
    inoremap <silent> <buffer> <expr> <C-v> unite#do_action('vsplit')
    "タブで開く
    nnoremap <silent> <buffer> <expr> <C-t> unite#do_action('tabopen')
    inoremap <silent> <buffer> <expr> <C-t> unite#do_action('tabopen')
    "その場所に開く
    nnoremap <silent> <buffer> <expr> <C-o> unite#do_action('open')
    inoremap <silent> <buffer> <expr> <C-o> unite#do_action('open')
endfunction"}}}
"unite end #####################################################################

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

"quickrun start ################################################################
let g:quickrun_config = {
\   "_" : {
\       "hook/close_unite_quickfix/enable_hook_loaded" : 1,
\       "hook/unite_quickfix/enable_failure" : 1,
\       "hook/close_quickfix/enable_exit" : 1,
\       "hook/close_buffer/enable_failure" : 1,
\       "hook/close_buffer/enable_empty_data" : 1,
\       "outputter" : "multi:buffer:quickfix",
\       "hook/shabadoubi_touch_henshin/enable" : 1,
\       "hook/shabadoubi_touch_henshin/wait" : 20,
\       "outputter/buffer/split" : ":8split",
\       "runner" : "vimproc",
\       "runner/vimproc/updatetime" : 40,
\   },
\    'php': {
\        'command':                             'php',
\        'exec':                                '%c %s',
\        'hook/close_buffer/enable_empty_data': 0,
\        'hook/close_buffer/enable_failure':    0,
\        'outputter':                           'buffer',
\        'outputter/buffer/close_on_empty':     0,
\        'outputter/buffer/into':               0,
\        'outputter/buffer/split':              ':botright 13sp'
\    },
\    'phpunit': {
\        'command':   'phpunit',
\        'exec':      '%c %s',
\        'outputter': 'buffer'
\    }
\}



:command! -nargs=1 Qr call s:Quick_run(<f-args>)
:function! s:Quick_run(...)
: if a:0 >= 1
:   let hogearg = a:1
:   execute 'QuickRun ' . a:1
: else
: end
:endfunction
"quickrun end  #################################################################

"Yggdroot/indentLine start #####################################################
" Vim
let g:indentLine_color_term = 239
" GVim
let g:indentLine_color_gui = '#A4E57E'
" none X terminal
let g:indentLine_color_tty_light = 7 " (default: 4)
let g:indentLine_color_dark = 1 " (default: 2)

" Background (Vim, GVim)
"let g:indentLine_bgcolor_term = 202
"let g:indentLine_bgcolor_gui = '#FF5F00'
"Yggdroot/indentLine end #######################################################

" ntpeters/vim-better-whitespace start ########################################
:highlight ExtraWhitespace ctermbg=darkgreen guibg=lightgreen
let g:better_whitespace_filetypes_blacklist=['vimfiler', 'diff', 'gitcommit', 'unite', 'qf', 'help']
nnoremap sws :<C-u>StripWhitespace<CR>
" ntpeters/vim-better-whitespace end ##########################################

"Yggdroot/indentLine start  #########################################
nnoremap ilt :<C-u>IndentLinesToggle<CR>
"Yggdroot/indentLine end    #########################################

"ctrlp start ###################################################################
nnoremap [ctrlp]    <Nop>
nmap     <Leader>c [ctrlp]
nnoremap [ctrlp]p :<C-u>CtrlP<CR>
nnoremap [ctrlp]b :<C-u>CtrlPBuffer<CR>
nnoremap [ctrlp]d :<C-u>CtrlPDir<CR>
nnoremap [ctrlp]f :<C-u>CtrlP<CR>
nnoremap [ctrlp]l :<C-u>CtrlPLine<CR>
nnoremap [ctrlp]m :<C-u>CtrlPMRUFiles<CR>
nnoremap [ctrlp]k :<C-u>CtrlPBookmark<CR>
nnoremap [ctrlp]q :<C-u>CtrlPQuickfix<CR>
nnoremap [ctrlp]s :<C-u>CtrlPMixed<CR>
nnoremap [ctrlp]t :<C-u>CtrlPTag<CR>

let g:ctrlp_map = '<Nop>'
" Guess vcs root dir
let g:ctrlp_working_path_mode = 'ra'
" Open new file in current window
let g:ctrlp_open_new_file = 'r'
let g:ctrlp_extensions = ['tag', 'quickfix', 'dir', 'line', 'mixed']
let g:ctrlp_match_window = 'bottom,order:btt,min:1,max:18'
let g:ctrlp_user_command = 'ag %s -l'
"cnnoremap [ctrlp]trlp end   ###################################################################

"tpope/vim-fugitive start   ###################################################################
nnoremap [fugitive] <Nop>
nmap     <Leader>fu [fugitive]
nnoremap [fugitive]s  :<C-u>Gstatus<CR>
nnoremap [fugitive]d :<C-u>Gvdiff<CR>
nnoremap [fugitive]l  :<C-u>Glog<CR>
nnoremap [fugitive]b :<C-u>Gblame<CR>
nnoremap [fugitive]rd :<C-u>Gread<CR>
nnoremap [fugitive]g :<C-u>Ggrep
nnoremap [fugitive]w :<C-u>Gbrowse<CR>

"tpope/vim-fugitive end      ###################################################################

"osyo-manga/vim-anzu' start  ###################################################################
" mapping
nmap n <Plug>(anzu-n-with-echo)
nmap N <Plug>(anzu-N-with-echo)
nmap * <Plug>(anzu-star-with-echo)
nmap # <Plug>(anzu-sharp-with-echo)

" clear status
nmap <Esc><Esc> <Plug>(anzu-clear-search-status)
" statusline
set statusline=%{anzu#search_status()}
"osyo-manga/vim-anzu' end    ###################################################################

nnoremap [tagbar]    <Nop>
nmap     <Leader>t [tagbar]
nnoremap [tagbar]t :<C-u>TagbarToggle<CR>
"ivalkeen/vim-ctrlp-tjump start  ###################################################################
nnoremap [tagbar]p :CtrlPtjump<cr>
vnoremap [tagbar]p :CtrlPtjumpVisual<cr>
"ivalkeen/vim-ctrlp-tjump end    ###################################################################

"soramugi/auto-ctags.vim  start  ###################################################################
let g:auto_ctags = 0
let g:auto_ctags_directory_list = ['.git', '.svn']
set tags+=.svn/tags
"soramugi/auto-ctags.vim  end    ###################################################################

"airblade/vim-gitgutter   start  ###################################################################
nnoremap [gitgutter]    <Nop>
nmap     <Leader>g [gitgutter]
nnoremap [gitgutter]t :<C-u>GitGutterLineHighlightsToggle<CR>
"nnoremap [gitgutter]n :<c-u>GitGutterNextHunk<cr>
nnoremap [gitgutter]n :call NextHunkAllBuffers()<cr>
nnoremap [gitgutter]p :call PrevHunkAllBuffers()<cr>
"カーソル行だけステージングに追加する、Git diffで表示されなくなる
nnoremap [gitgutter]s :<C-u>GitGutterStageHunk<CR>
nnoremap [gitgutter]u :<C-u>GitGutterUndoHunk<CR>
nnoremap [gitgutter]v :<C-u>GitGutterPreviewHunk<CR>
nnoremap [gitgutter]a :<C-u>GitGutterAll<CR>
"バッファで次のハンクがあれば移動する
function! NextHunkAllBuffers()
  let line = line('.')
  let firstLine  = line('w0')
  let lastLine   = line('w$')
  "let halfDistance  = ((lastLine - firstLine) / 2)
  let halfLine = ((lastLine - firstLine) / 2) + firstLine
  "((line('w$') - line('w0')) / 2) + line('w0')
  GitGutterNextHunk

  "let movedDistance = line('.') - line
  "if movedDistance > halfDistance
" 画面の半分以上移動したら真ん中に表示させる
  if line('.') > halfLine
      :norm zz<cr>
  endif

  if line('.') != line
    return
  endif

  let bufnr = bufnr('')
  while 1
    bnext
    if bufnr('') == bufnr
      return
    endif
    if !empty(GitGutterGetHunks())
      normal! 1G
      GitGutterNextHunk
      :norm zz<cr>
      return
    endif
  endwhile
endfunction

function! PrevHunkAllBuffers()
  let line = line('.')
  let firstLine = line('w0')
  let lastLine = line('w$')
  let halfLine = ((lastLine - firstLine) / 2) + firstLine
  GitGutterPrevHunk

  if line('.') < halfLine
      :norm zz<cr>
  endif

  if line('.') != line
    return
  endif

  let bufnr = bufnr('')
  while 1
    bprevious
    if bufnr('') == bufnr
      return
    endif
    if !empty(GitGutterGetHunks())
      normal! G
      GitGutterPrevHunk
      :norm zz<cr>
      return
    endif
  endwhile
endfunction
"airblade/vim-gitgutter   end   ###################################################################

"rhysd/clever-f.vim ##################################################
let g:clever_f_smart_case = 1
"rhysd/clever-f.vim ##################################################

"deris/vim-gothrough-jk  ##################################################
" let g:gothrough_jk_go_step = 5
"deris/vim-gothrough-jk  ##################################################

"Plug 'easymotion/vim-easymotion' start ##################################################
let g:EasyMotion_do_mapping = 0 " Disable default mappings
let g:EasyMotion_smartcase = 1

nnoremap [easymotion]    <Nop>
nmap <Leader> [easymotion]

map [easymotion] <Plug>(easymotion-prefix)

" <Leader>f{char} to move to {char}
" map  [easymotion]f <Plug>(easymotion-bd-f)
" nmap [easymotion]f <Plug>(easymotion-overwin-f)

" Turn on case insensitive feature

" s{char}{char} to move to {char}{char}
" Jump to anywhere you want with minimal keystrokes, with just one key binding.
" `s{char}{label}`
"nmap s <Plug>(easymotion-overwin-f)
" or
" `s{char}{char}{label}`
" Need one more keystroke, but on average, it may be more comfortable.
"nmap s <Plug>(easymotion-overwin-f2)

" Gif config
"nmap s <Plug>(easymotion-s2)
"nmap t <Plug>(easymotion-t2)

" Gif config
"map  / <Plug>(easymotion-sn)
"omap / <Plug>(easymotion-tn)

" These `n` & `N` mappings are options. You do not have to map `n` & `N` to EasyMotion.
" Without these mappings, `n` & `N` works fine. (These mappings just provide
" different highlight method and have some other features )
"map  n <Plug>(easymotion-next)
"map  N <Plug>(easymotion-prev)

" Move to line
map [easymotion]L <Plug>(easymotion-bd-jk)
nmap [easymotion]L <Plug>(easymotion-overwin-line)

" JK motions: Line motions
map [easymotion]l <Plug>(easymotion-lineforward)
map [easymotion]n <Plug>(easymotion-j)
" map [easymotion]k <Plug>(easymotion-k)
map [easymotion]h <Plug>(easymotion-linebackward)

" Move to word
"map  [easymotion]w <Plug>(easymotion-bd-w)
"nmap [easymotion]w <Plug>(easymotion-overwin-w)
"Plug 'easymotion/vim-easymotion' end  ##################################################

"Plug 'elzr/vim-json' start ##################################################
let g:vim_json_syntax_conceal = 0
"Plug 'elzr/vim-json' end ##################################################

"Plug 'scrooloose/nerdcommenter' start ##################################################
let g:NERDCreateDefaultMappings = 0
let g:NERDSpaceDelims =1
let g:NERDDefaultAlign ='left'
nnoremap [nerdcommenter]    <Nop>
nmap <Leader>, [nerdcommenter]
vmap <Leader>, [nerdcommenter]

nnoremap [nerdcommenter]<space> :call NERDComment(0,"toggle")<CR>
vnoremap [nerdcommenter]<space> :call NERDComment(0,"toggle")<CR>
nnoremap [nerdcommenter]s :call NERDComment(0,"Sexy")<CR>
vnoremap [nerdcommenter]s :call NERDComment(0,"Sexy")<CR>
"Plug 'scrooloose/nerdcommenter' end ##################################################


" Plug 'scrooloose/nerdtree' start ####################################################
nnoremap ,t :NERDTreeTabsToggle<CR>
" Plug 'scrooloose/nerdtree' end ######################################################

" Plug 'scrooloose/nerdtree' #########################################################
let NERDTreeShowBookmarks=1
let g:NERDTreeMapActivateNode ='l'
let g:NERDTreeMapOpenVSplit ='v'

autocmd VimEnter * call NERDTreeAddKeyMap({
  \ 'key': 'b',
  \ 'callback': 'NERDTreeToggleBookmark',
  \ 'quickhelpText': 'Add/Remove Bookmark for Node.',
  \ 'scope': 'Node' })

function! NERDTreeToggleBookmark(node)
  let bookmarkName = a:node.path.getLastPathComponent(1)

  try
    let bookmark = g:NERDTreeBookmark.BookmarkFor(bookmarkName)
    if a:node.path.compareTo(bookmark.path) == 0 "If Paths are equal.
      call bookmark.delete()
    endif
  catch /^NERDTree.BookmarkNotFoundError/
    call a:node.bookmark(bookmarkName)
  endtry
  call g:NERDTree.ForCurrentTab().getRoot().refresh()

  call NERDTreeRender()
  " call a:node.putCursorHece(1, 1)
endfunction
" Plug 'sccooloose/nerdtree' #########################################################

"vim-syntastic/syntastic start ####################################################################
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
"vim-syntastic/syntastic end  ####################################################################

"Plug 'tyru/current-func-info.vim' ###################################################################
nnoremap <C-g>j :echo cfi#format("%s", "")<CR>
let &statusline .= ' [%{cfi#format("%s", "")}]'
"Plug 'tyru/current-func-info.vim' ###################################################################

" Plug 'leafcage/yankround.vim' ######################################################################
nnoremap <leader>y :<C-u>Unite yankround<CR>
" Plug 'leafcage/yankround.vim' ######################################################################

" Plug 'ujihisa/unite-colorscheme' ###################################################################
nnoremap <silent> [unite]clrs    :<C-u>Unite -auto-preview colorscheme <CR>
" Plug 'ujihisa/unite-colorscheme' ###################################################################

" Plug 'rhysd/accelerated-jk'#########################################################################
let g:accelerated_jk_enable_deceleration=1
nmap j <Plug>(accelerated_jk_gj)
nmap k <Plug>(accelerated_jk_gk)
" Plug 'rhysd/accelerated-jk'#########################################################################

" Plug 'Shougo/deol.nvim'#############################################################################
nnoremap dl :<C-u>Deol<CR>
tnoremap <ESC>   <C-\><C-n>
" Plug 'Shougo/deol.nvim'#############################################################################

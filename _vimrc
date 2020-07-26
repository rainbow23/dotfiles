set backspace=indent,eol,start
set number
set matchtime=1
set autoindent
set shiftwidth=4
set tabstop=4
set noswapfile
set ignorecase
set noshowmode
set tags+=.git/tags
set pumheight=10
set splitright
" 開いたファイルにワーキングディレクトリを移動する
if 1 == exists("+autochdir")
    set autochdir
endif
syntax on
colorscheme peachpuff
filetype on
set hlsearch
hi Search ctermbg=Gray
hi Search ctermfg=Black
" visual mode hightlight color
hi Visual ctermbg=LightRed
hi Visual ctermfg=DarkBlue
hi Comment ctermfg=Cyan
set encoding=utf-8

autocmd BufEnter *.yml,*.yaml,*.sh,*.zsh,_zshrc,_vimrc,*.vim set shiftwidth=2
autocmd BufEnter *.php set noexpandtab " Use tabs, not spaces
autocmd BufEnter *.php set tabstop=4
" %retab!            "spaceをtabに変換

"ヤンクをクリップボードに保存　kana/vim-fakeclipと連動
set clipboard=unnamed
" タブ入力を複数の空白入力に置き換える
set expandtab
" 画面上でタブ文字が占める幅
set tabstop=4

let mapleader = "\<Space>"
"let mapleader = ","

nnoremap Y y$
set display=lastline
nnoremap + <C-a>
nnoremap - <C-x>
"カーソル位置から画面移動
nnoremap .t zt
nnoremap .m zz
nnoremap .b zb

nnoremap sn :<C-u>set number<CR>
nnoremap snn :<C-u>set nonumber<CR>
nnoremap srn :<C-u>setlocal relativenumber!<CR>
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

noremap ter :100VTerm<CR>
noremap tert :TTerm<CR>
" 次の行からインサードモードで始める
nnoremap nl $a<CR>
inoremap nl <ESC>$a<CR>
" move cursor to end position
inoremap edp <ESC>$a
" 折返し無し
set nowrap
nnoremap swp :<C-u>set nowrap!<CR>
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

highlight Directory ctermfg=cyan

" panel size start ################################

" resize panes
nnoremap <silent> <Left> :vertical resize -10<CR>
nnoremap <silent> <Right> :vertical resize +10<CR>
nnoremap <silent> <Up> :resize +10<CR>
nnoremap <silent> <Down> :resize -10<CR>
nnoremap <C-s> :split <C-g><CR>
nnoremap exg <C-w>x <C-g><CR>
noremap w= <C-w>= <C-g><CR>
" panel size end  #################################

" Plug 'regedarek/ZoomWin' ###########################################################################
" 選択したパネルの最大化
nnoremap <silent> zwo :<C-u>ZoomWin<CR>

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

" 削除でヤンクしない
nnoremap x "_x
nnoremap dd "_dd
nnoremap dw "_dw
nnoremap d$ "_d$
nnoremap diw "_diw
nnoremap ; :
nnoremap : ;
" Count number of matches of a pattern
" http://vim.wikia.com/wiki/Count_number_of_matches_of_a_pattern
nnoremap 88 *<C-O>:%s///gn<CR>

"改行後INSERT MODEにしない
nnoremap O :<C-u>call append(expand('.'), '')<Cr>j
"検索ハイライトを消す
nnoremap ns :<C-u>nohlsearch<CR>

"進む 一行
nnoremap <silent> <C-e> <C-e>j
"進む 画面半分
nnoremap <silent> <C-d> <C-d>zz
"進む 画面1ページ分
nnoremap <silent> <C-f> <C-f>zz
"戻る 一行
nnoremap <silent> <C-y> <C-y>k
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
nnoremap <Leader>. :<C-u>tabedit $HOME/dotfiles/_vimrc<CR>
:set list lcs=tab:\|\ 


if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'junegunn/vim-easy-align'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/vim-peekaboo'
Plug 'Shougo/unite.vim'
Plug 'rainbow23/unite-session'
Plug 'Shougo/neomru.vim'
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
Plug 'rainbow23/vim-anzu'
Plug 'majutsushi/tagbar'
Plug 'rhysd/clever-f.vim'
Plug 'rainbow23/vim-bookmarks', { 'branch': 'fzf' }
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
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
    let g:python3_host_prog = expand('/usr/local/bin/python3')
elseif has("unix")
    let g:python3_host_prog = expand('/usr/local/bin/python3')
endif

if has('pythonx')
    set pyxversion=3
endif
if has('python3')
:python3 import neovim
endif
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'
Plug 'rainbow23/vim-snippets'
Plug 'padawan-php/deoplete-padawan', { 'do': 'composer install' }
Plug 'zchee/deoplete-go', { 'do': 'make'}
Plug 'fatih/vim-go', { 'tag': 'v1.19', 'do': ':GoUpdateBinaries' }
Plug 'mdempsky/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }
Plug 'Shougo/neco-syntax'
Plug 'machakann/vim-sandwich'
Plug 'ntpeters/vim-better-whitespace'
Plug 'tyru/current-func-info.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'regedarek/ZoomWin'
Plug 'leafcage/yankround.vim'
Plug 'ujihisa/unite-colorscheme'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
" 対応する括弧
Plug 'itchyny/vim-parenmatch'
Plug 'itchyny/vim-cursorword'
Plug 'yuttie/comfortable-motion.vim'
Plug 'mileszs/ack.vim'
Plug 'thinca/vim-qfreplace'
Plug 'vimlab/split-term.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'matze/vim-move'
Plug 'mcchrish/nnn.vim'
Plug 't9md/vim-quickhl'
Plug 'lighttiger2505/sqls.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/async.vim'
Plug 'lighttiger2505/deoplete-vim-lsp'
Plug 'mattn/vim-lsp-settings' ":LspInstallServer"
Plug 'mattn/vim-goimports'
Plug 'iberianpig/tig-explorer.vim'
Plug 'rbgrouleff/bclose.vim'
Plug 'alvan/vim-closetag'
Plug 'machakann/vim-highlightedyank'
call plug#end()

"FZF start ####################################################################
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

function! s:Uss(file)
    execute 'UniteSessionLoad ' . a:file
    " echo a:file
endfunction

nnoremap [fzf]us :<C-u>MyUniteSessionLoad<CR>
command! MyUniteSessionLoad  call fzf#run({
      \ 'source': "ls -l ~/.vim/etc/unite/session | sed '1d' | awk '{print $9}'",
      \ 'sink': function('<sid>Uss'),
      \ 'options': '+m',
      \ 'right': '40%'})

nnoremap [fzf]m :<C-u>FZFMru<CR>
nnoremap [fzf]f :<C-u>Files<CR>
" git ls-files
nnoremap [fzf]g :<C-u>GFiles<CR>
nnoremap [fzf]gs :<C-u>GFiles?<CR>
" git staus
nnoremap [fzf]G :<C-u>GFiles?<CR>
nnoremap [fzf]b :<C-u>Buffers<CR>
nnoremap [fzf]h :<C-u>History<CR>
" list tabs
nnoremap [fzf]w :<C-u>Windows<CR>
nnoremap [fzf]a :<C-u>Ag<CR>
nnoremap [fzf]l :<C-u>BLines<CR>
nnoremap [fzf]s :<C-u>Search<CR>
nnoremap [fzf]S :<C-u>SearchFromCurrDir<CR>
nnoremap [fzf]k :<C-u>FzfGitRootDirBookmarks!<CR>
nnoremap [fzf]K :<C-u>FzfCurrFileBookmarks!<CR>
nnoremap [fzf]ka :<C-u>FzfAllBookmarks!<CR>

let g:fzf_layout = { 'down': '~30%' }
let s:fzf_base_options = extend({'options': ''}, g:fzf_layout)

function! s:with_git_root()
  let root = systemlist('git rev-parse --show-toplevel')[0]
  return v:shell_error ? {} : {'dir': root}
endfunction

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

command! -bang -nargs=* FZFMru call fzf#vim#history(fzf#vim#with_preview())

command! -bang -nargs=? GFiles
\ call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview(), <bang>0),

command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

 " Make Ripgrep ONLY search file contents and not filenames
command! -bang -nargs=* Search
  \ call fzf#vim#grep(
  \   'rg --column --line-number --hidden --smart-case --no-heading --color=always ^ $(git rev-parse --show-toplevel) '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
  \           : fzf#vim#with_preview({'options': '--delimiter : --nth 4.. -e'}, 'right:30%', '?'),
  \   <bang>0)

command! -bang -nargs=* SearchFromCurrDir
  \ call fzf#vim#grep(
  \   'rg --column --line-number --hidden --smart-case --no-heading --color=always ^ $(pwd) '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview({'options': '--delimiter : --nth 4..'}, 'up:60%')
  \           : fzf#vim#with_preview({'options': '--delimiter : --nth 4.. -e'}, 'right:30%', '?'),
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
let g:airline_section_b = '%{getcwd()}' " in section B of the status line display the CWD

let g:airline#extensions#tabline#enabled           = 1   " enable airline tabline
let g:airline#extensions#tabline#show_close_button = 0   " remove 'X' at the end of the tabline
let g:airline#extensions#tabline#tabs_label        = ''  " can put text here like BUFFERS to denote buffers (I clear it so nothing is shown)
let g:airline#extensions#tabline#buffers_label     = ''  " can put text here like TABS to denote tabs (I clear it so nothing is shown)
let g:airline#extensions#tabline#fnamemod          = ':t'" disable file paths in the tab
let g:airline#extensions#tabline#show_tab_count    = 0   " dont show tab numbers on the right
let g:airline#extensions#tabline#show_buffers      = 0   " dont show buffers in the tabline
let g:airline#extensions#tabline#tab_min_count     = 2   " minimum of 2 tabs needed to display the tabline
let g:airline#extensions#tabline#show_splits       = 0   " disables the buffer name that displays on the right of the tabline
let g:airline#extensions#tabline#show_tab_nr       = 0   " disable tab numbers
let g:airline#extensions#tabline#show_tab_type     = 0   " disables the weird ornage arrow on the tabline
let g:airline#extensions#tabline#show_buffers      = 1   " dont show buffers in the tabline

"vim-airline end  #####################################################################

"neosnippets start #################################################################
" which disables all runtime snippets
" let g:neosnippet#disable_runtime_snippets = {
" \   '_' : 1,
" \ }
" Enable snipMate compatibility feature.
let g:neosnippet#enable_snipmate_compatibility = 1
" Tell Neosnippet about the other snippets
let g:neosnippet#snippets_directory='~/.vim/plugged/vim-snippets/snippets/'
" ~/.vim/bundle/vim-snippets/snippets'

" Plugin key-mappings.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
" use together neosnippet and deoplete
imap <expr><C-o>
\ pumvisible() ? neosnippet#expandable_or_jumpable() ?
\    "\<Plug>(neosnippet_expand_or_jump)" : deoplete#close_popup() :
\    "\<Plug>(neosnippet_expand_or_jump)" "neosnippetの２回目以降で移動する場合に使用する
smap <expr><C-o>
\ pumvisible() ? neosnippet#expandable_or_jumpable() ?
\    "\<Plug>(neosnippet_expand_or_jump)" : deoplete#close_popup() :
\    "\<Plug>(neosnippet_expand_or_jump)" "neosnippetの２回目以降で移動する場合に使用する
xmap <C-o>     <Plug>(neosnippet_expand_target)

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

inoremap <silent> <expr> <CR>  pumvisible() ? deoplete#close_popup() : "\n"
inoremap <silent> <expr> <C-j> pumvisible() ? "\<C-n>" : ""
inoremap <silent> <expr> <C-k> pumvisible() ? "\<C-p>" : ""

" <CR>: close popup.
" <C-r>=  used to insert the result of an expression at the cursor
" https://stackoverflow.com/questions/10862457/what-does-c-r-means-in-vim/10863134
" inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
" inoremap <silent> <C-j> <C-r>=<SID>my_cj_function()<CR>
" inoremap <silent> <C-k> <C-r>=<SID>my_ck_function()<CR>

" function! s:my_cr_function()
"     return pumvisible() ? deoplete#mappings#close_popup() : "\n"
" endfunction

" function! s:my_cj_function()
"     return pumvisible() ? "\<C-n>" : ""
" endfunction

" function! s:my_ck_function()
"     return pumvisible() ? "\<C-p>" : ""
" endfunction

inoremap <silent><expr> <TAB>
\ pumvisible() ? "\<C-n>" :
\ <SID>check_back_space() ? "\<TAB>" :
\ deoplete#mappings#manual_complete()

function! s:check_back_space() abort "{{{
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~ '\s'
endfunction"}}}
" deoplete end #####################################################################

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
nnoremap <silent> uo :<C-u>Unite -auto-resize outline<CR>
nnoremap <silent> uov :<C-u>Unite -vertical -winwidth=50 outline<CR>
nnoremap <silent> uv :<C-u>Unite -auto-resize output:version<CR>

" 'rainbow23/vim-bookmarks.git' start ****************************************************
highlight BookmarkLine ctermbg=238 ctermfg=none
highlight BookmarkAnnotationLine ctermbg=238 ctermfg=none
let g:bookmark_highlight_lines = 1
let g:bookmark_center = 1
let g:bookmark_prefer_fzf = 1
let g:bookmark_fzf_preview_layout = ['down', '40%']
let g:bookmark_auto_save = 1
" below feature work with g:BMWorkDirFileLocation()
let g:bookmark_save_per_working_dir = 1

" Finds the Git super-project directory.
function! g:BMWorkDirFileLocation()
    let filename = 'bookmarks'
    let location = ''
    if isdirectory('.git')
        " Current work dir is git's work tree
        let location = getcwd().'/.git'
    else
        " Look upwards (at parents) for a directory named '.git'
        let location = finddir('.git', '.;')
    endif
    if len(location) > 0
        return location.'/'.filename
    else
        return getcwd().'/.'.filename
    endif
endfunction
" 'rainbow23/vim-bookmarks.git' end ******************************************************

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
if executable('rg')
  let g:unite_source_grep_command = 'rg'
  let g:unite_source_grep_default_opts = '--nogroup --nocolor --column'
  let g:unite_source_grep_recursive_opt = ''
endif
"全体に適応 end    ##########

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

" Disable Deoplete when selecting multiple cursors starts
function! Multiple_cursors_before()
  let g:cursorword = 0
  if exists('*deoplete#disable')
    exe 'call deoplete#disable()'
  elseif exists(':NeoCompleteLock') == 2
    exe 'NeoCompleteLock'
  endif
endfunction
function! Multiple_cursors_after()
  let g:cursorword = 1
 if exists('*deoplete#enable')
   exe 'call deoplete#enable()'
 elseif exists(':NeoCompleteUnlock') == 2
   exe 'NeoCompleteUnlock'
 endif
endfunction

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

"tpope/vim-fugitive start   ###################################################################
nnoremap [fugitive] <Nop>
nmap     <Leader>v [fugitive]
nnoremap [fugitive]s  :<C-u>Gstatus<CR>
nnoremap [fugitive]d :<C-u>Gvdiff<CR>
nnoremap [fugitive]l  :<C-u>Glog<CR>
nnoremap [fugitive]b :<C-u>Gblame<CR>
nnoremap [fugitive]rd :<C-u>Gread<CR>:GitGutterAll<CR>
nnoremap [fugitive]g :<C-u>Ggrep
nnoremap [fugitive]w :<C-u>Gbrowse<CR>

autocmd BufWritePost *
      \ if exists('b:git_dir') && executable(b:git_dir.'/hooks/ctags') |
      \   call system('"'.b:git_dir.'/hooks/ctags" &') |
      \ endif
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

"airblade/vim-gitgutter   start  ###################################################################
highlight clear SignColumn
highlight GitGutterAdd        cterm=bold ctermfg=2    ctermbg=18
highlight GitGutterChange     cterm=bold ctermfg=7    ctermbg=54
highlight GitGutterDelete     cterm=bold ctermfg=164  ctermbg=53
highlight DiffText            cterm=bold ctermfg=none ctermbg=54 gui=none
highlight GitGutterAddLine    cterm=bold ctermfg=none ctermbg=18 gui=none
highlight GitGutterDeleteLine cterm=bold ctermfg=none ctermbg=52 gui=none
highlight link GitGutterChangeLine DiffText
let g:gitgutter_preview_win_floating = 0

autocmd TextChanged * GitGutterAll
nnoremap [gitgutter]    <Nop>
nmap     <Leader>g [gitgutter]
nnoremap [gitgutter]t :<C-u>GitGutterLineHighlightsToggle<CR>
"nnoremap [gitgutter]n :<c-u>GitGutterNextHunk<cr>
nnoremap [gitgutter]n :call NextHunkAllBuffers()<cr>
nnoremap [gitgutter]p :call PrevHunkAllBuffers()<cr>
"カーソル行だけステージングに追加する、Git diffで表示されなくなる
nnoremap [gitgutter]s :<C-u>GitGutterStageHunk<CR>
nnoremap [gitgutter]u :<C-u>GitGutterUndoHunk<CR>:<C-u>GitGutterAll<CR>
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

hi EasyMotionTarget ctermbg=none ctermfg=green

nnoremap [easymotion]    <Nop>
nmap <Leader> [easymotion]
map [easymotion] <Plug>(easymotion-prefix)
map  <Leader><Leader> <Plug>(easymotion-bd-w)
nmap <Leader><Leader> <Plug>(easymotion-overwin-w)

" カーソルより下の行を検索
nmap t <Plug>(easymotion-t2)

" surround.vimと被らないように
omap z <Plug>(easymotion-s2)

nmap g/ <Plug>(easymotion-sn)
omap g/ <Plug>(easymotion-tn)
" below optin does not work
" easymotion-next
" easymotion-prev

" Move to line
map [easymotion]L <Plug>(easymotion-bd-jk)
nmap [easymotion]L <Plug>(easymotion-overwin-line)

" JK motions: Line motions
map [easymotion]l <Plug>(easymotion-lineforward)
map [easymotion]n <Plug>(easymotion-j)
map [easymotion]K <Plug>(easymotion-k)
map [easymotion]h <Plug>(easymotion-linebackward)
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
nmap p <Plug>(yankround-p)
xmap p <Plug>(yankround-p)
nmap P <Plug>(yankround-P)
nmap gp <Plug>(yankround-gp)
xmap gp <Plug>(yankround-gp)
nmap gP <Plug>(yankround-gP)
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
noremap <ESC>   <C-\><C-n>
" Plug 'Shougo/deol.nvim'#############################################################################

" Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' } #################################################
let g:go_term_mode = "vsplit"

augroup go
  autocmd!
  autocmd BufNewFile,BufRead *.go call <SID>CloseAllGoRunWindow()
augroup END

nnoremap [go]    <Nop>
nmap     go [go]
nnoremap <silent> [go]r :call <SID>MyGoRun()<CR>
nnoremap <silent> [go]b :call <C-u>:GoBuild<CR>

fun! s:MyGoRun()
    let l:winWidth = winwidth("%")
    let l:closeWinNum = s:CloseAllGoRunWindow()

    :set splitright
    :GoRun<CR>
    :set nosplitright

    if l:closeWinNum >= 1
        exe "vertical resize" . str2nr(l:winWidth)
    endif
endfun

fun! s:CloseAllGoRunWindow()
  let l:closeNum = 0
    for w in range(1, winnr('$'))
        if getwinvar(w, '&filetype') == "goterm"
            " windowを閉じる
            exe eval(w)."q"
            let l:closeNum += 1
            " windowを閉じたらwindows番号が変わるため最初から実行する
            :call <SID>CloseAllGoRunWindow()
        endif
    endfor
    return l:closeNum
endfun
" Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' } #################################################

" Plug 'itchyny/vim-parenmatch' ######################################################################
let g:loaded_matchparen = 1
" Plug 'itchyny/vim-parenmatch' ######################################################################

" Plug 'yuttie/comfortable-motion.vim' ###############################################################
let g:comfortable_motion_no_default_key_mappings = 1
let g:comfortable_motion_friction = 200.0
let g:comfortable_motion_air_drag = 4.0

let g:comfortable_motion_impulse_multiplier = 1.5  " Feel free to increase/decrease this value.
" nnoremap <Leader>j :call comfortable_motion#flick(100)<CR>
nnoremap <silent> <Leader>j :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * 2)<CR>
nnoremap <silent> <Leader>k :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * -2)<CR>
nnoremap <silent> <C-d> :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * 2)<CR>
nnoremap <silent> <C-u> :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * -2)<CR>
nnoremap <silent> <C-f> :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * 4)<CR>
nnoremap <silent> <C-b> :call comfortable_motion#flick(g:comfortable_motion_impulse_multiplier * winheight(0) * -4)<CR>
" Plug 'yuttie/comfortable-motion.vim' ###############################################################

" Plug 'mileszs/ack.vim' #############################################################################
if executable("rg")
  let g:ackprg = 'rg --vimgrep --no-heading'
endif
" Plug 'mileszs/ack.vim' #############################################################################

" Plug 'thinca/vim-qfreplace' ########################################################################
nnoremap qfr :Qfreplace<CR>
" Plug 'thinca/vim-qfreplace' ########################################################################

" Plug 'matze/vim-move' ###############################################################################
let g:move_map_keys = 0
vmap <C-j> <Plug>MoveBlockDown
vmap <C-k> <Plug>MoveBlockUp
" Plug 'matze/vim-move' ###############################################################################

" Plug 'mcchrish/nnn.vim' #############################################################################
let g:nnn#set_default_mappings = 0
nnoremap <silent> <leader>nn :NnnPicker<CR>
let g:nnn#action = {
      \ '<c-t>': 'tab split',
      \ '<c-x>': 'split',
      \ '<c-v>': 'vsplit' }
" Plug 'mcchrish/nnn.vim' #############################################################################
" Plug t9md/vim-quickhl ###############################################################################
nmap <Space>m <Plug>(quickhl-manual-this)
xmap <Space>m <Plug>(quickhl-manual-this)
nmap <F9>     <Plug>(quickhl-manual-toggle)
xmap <F9>     <Plug>(quickhl-manual-toggle)
nmap <Space>M <Plug>(quickhl-manual-reset)
xmap <Space>M <Plug>(quickhl-manual-reset)
nmap <Space>] <Plug>(quickhl-tag-toggle)
" map H <Plug>(operator-quickhl-manual-this-motion)
" Plug t9md/vim-quickhl ###############################################################################

" lighttiger2505/sqls ##############################################################
nnoremap seq :SqlsExecuteQuery<CR>
nnoremap ssc :SqlsShowConnections<CR>
nnoremap ssd :SqlsSwitchDatabase<CR>
" localにsqlサーバたてる方法
" go get github.com/lighttiger2505/sqls
" cd $GOPATH/src/github.com/lighttiger2505/sqls
" docker-compse up -d

if executable('sqls')
    augroup LspSqls
        autocmd!
        autocmd User lsp_setup call lsp#register_server({
        \   'name': 'sqls',
        \   'cmd': {server_info->['sqls']},
        \   'whitelist': ['sql'],
        \   'workspace_config': {
        \     'sqls': {
        \       'connections': [
        \         {
        \           'driver': 'mysql',
        \           'dataSourceName': 'root:root@tcp(127.0.0.1:13306)/world',
        \         },
        \         {
        \           'driver': 'mysql',
        \           'dataSourceName': 'root:root@tcp(127.0.0.1:43306)/todo',
        \         },
        \         {
        \           'driver': 'postgresql',
        \           'dataSourceName': 'host=127.0.0.1 port=15432 user=postgres password=mysecretpassword1234 dbname=dvdrental sslmode=disable',
        \         },
        \       ],
        \     },
        \   },
        \ })
    augroup END
endif
" lighttiger2505/sqls ##############################################################

" Plug 'alvan/vim-closetag' #########################################################
" filenames like *.xml, *.html, *.xhtml, ...
" These are the file extensions where this plugin is enabled.
"
let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.vue'

" filenames like *.xml, *.xhtml, ...
" This will make the list of non-closing tags self-closing in the specified files.
"
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx'

" filetypes like xml, html, xhtml, ...
" These are the file types where this plugin is enabled.
"
let g:closetag_filetypes = 'html,xhtml,phtml'

" filetypes like xml, xhtml, ...
" This will make the list of non-closing tags self-closing in the specified files.
"
let g:closetag_xhtml_filetypes = 'xhtml,jsx'
" Plug 'alvan/vim-closetag' #########################################################

" Plug 'machakann/vim-highlightedyank' ##############################################
highlight HighlightedyankRegion cterm=reverse gui=reverse
let g:highlightedyank_highlight_duration = 500
" Plug 'machakann/vim-highlightedyank' ##############################################

" Plug 'christoomey/vim-tmux-navigator' #############################################
" Disable tmux navigator when zooming the Vim pane
let g:tmux_navigator_disable_when_zoomed = 1
" Plug 'christoomey/vim-tmux-navigator' #############################################

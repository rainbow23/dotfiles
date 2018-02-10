set backspace=indent,eol,start
set number
set showmatch
set matchtime=1
set autoindent
set shiftwidth=4
set tabstop=4
set noswapfile
set tags=./tags;
syntax on
set hlsearch
autocmd InsertLeave * set nopaste
"ヤンクをクリップボードに保存　kana/vim-fakeclipと連動
set clipboard=unnamed
" タブ入力を複数の空白入力に置き換える
set expandtab
" 画面上でタブ文字が占める幅
set tabstop=4
"fzf.vim 読み込み
set rtp+=/usr/local/opt/fzf

let mapleader = "\<Space>"
"let mapleader = ","

"カーソル位置から画面移動
nnoremap .t zt
nnoremap .m zz
nnoremap .b zb

nnoremap setp :<C-u>set paste<CR>

nnoremap [buffer]    <Nop>
nmap     <Leader>b [buffer]
nnoremap [buffer]p :bprevious<CR>
nnoremap [buffer]n :bnext<CR>
"前に開いたファイルを開く
nnoremap [buffer]r :b#<CR>
"直前のバッファを開く
nnoremap [buffer]d :bdelete<CR>

" panel size start ################################
nnoremap [panelwidthsize]    <Nop>
nmap     <Leader>pw [panelwidthsize]
nnoremap [panelwidthsize]j :vertical resize -10<CR>
nnoremap [panelwidthsize]k :vertical resize +10<CR>

nnoremap [panelheightsize]    <Nop>
nmap     <Leader>ph [panelheightsize]
nnoremap [panelheightsize]j :resize -10<CR>
nnoremap [panelheightsize]k :resize +10<CR>
" panel size end  #################################

nnoremap [ctrlw]    <Nop>
nmap     <Leader>w [ctrlw]
nnoremap [ctrlw]h <C-w>h
nnoremap [ctrlw]l <C-w>l
nnoremap [ctrlw]j <C-w>j
nnoremap [ctrlw]k <C-w>k

nnoremap <C-H> :noh <CR>
" 削除でヤンクしない
nnoremap x "_x
nnoremap dd "_dd
nnoremap dw "_dw
nnoremap d$ "_d$
nnoremap diw "_diw

nnoremap ; :
nnoremap : ;

"改行後INSERT MODEにしない
nnoremap O :<C-u>call append(expand('.'), '')<Cr>j
"nnoremap O o<Esc>

"ノーマルモード＋ビジュアルモード
noremap <C-j> <Esc>
"コマンドラインモード＋インサートモード
noremap! <C-j> <Esc>
noremap  <Leader>j <Esc>
noremap! <Leader>j <Esc>
"set termguicolors nvim用
"set nohlsearch
"set cursorline
"highlight Normal ctermbg=black ctermfg=white
highlight StatusLine term=none cterm=none ctermfg=black ctermbg=grey
"highlight CursorLine term=none cterm=none ctermfg=none ctermbg=grey
nnoremap <Leader>. :<C-u>tabedit $MYVIMRC<CR>
:set list lcs=tab:\|\ 

call plug#begin('~/.vim/plugged')
Plug 'junegunn/vim-easy-align'
"Plug 'powerline/fonts'
Plug 'Shougo/unite.vim'
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'
Plug 'Shougo/neocomplcache.vim'
Plug 'rainbow23/unite-session'
Plug 'Shougo/neomru.vim'
Plug 'Shougo/vimfiler.vim'
"unite-outline brew install ctagsが必要
Plug 'Shougo/unite-outline'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'kana/vim-fakeclip'
Plug 'terryma/vim-multiple-cursors'
Plug 'thinca/vim-quickrun'
Plug 'osyo-manga/unite-quickfix'
Plug 'Shougo/vimproc.vim', {'do' : 'make'}
Plug 'osyo-manga/shabadou.vim'
Plug 'Yggdroot/indentLine'
Plug 'bronson/vim-trailing-whitespace'
Plug 'ctrlpvim/ctrlp.vim'
"Plug 'cohama/lexima.vim'
Plug 'osyo-manga/vim-anzu'
Plug 'majutsushi/tagbar'
Plug 'rhysd/clever-f.vim'
Plug 'MattesGroeger/vim-bookmarks'
Plug 'ivalkeen/vim-ctrlp-tjump'
Plug 'tpope/vim-fugitive'
Plug 'soramugi/auto-ctags.vim'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf.vim'
Plug 'deris/vim-gothrough-jk'
Plug 'easymotion/vim-easymotion'
call plug#end()

command! FZFMru call fzf#run({
\ 'source':  reverse(s:all_files()),
\ 'sink':    'edit',
\ 'options': '-m -x +s',
\ 'down':    '40%' })

function! s:all_files()
  return extend(
  \ filter(copy(v:oldfiles),
  \        "v:val !~ 'fugitive:\\|NERD_tree\\|^/tmp/\\|.git/'"),
  \ map(filter(range(1, bufnr('$')), 'buflisted(v:val)'), 'bufname(v:val)'))
endfunction

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
let g:unite_data_directory = expand('~/.vim/etc/unite')
"インサートモードで開始
"let g:unite_enable_start_insert=1
"ヒストリー/ヤンク機能を有効化
let g:unite_source_history_yank_enable =1

"prefix keyの設定
nnoremap [unite]    <Nop>
nmap     <Leader>u [unite]

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

"全体に適応 start  ###############################################
nnoremap <silent> [unite]d :<C-u>Unite directory_mru<CR>
nnoremap <silent> [unite]b :<C-u>Unite buffer<CR>
nnoremap <silent> [unite]s :<C-u>Unite session<CR>
nnoremap <silent> [unite]t :<C-u>Unite tab<CR>
"スペースキーとrキーでレジストリを表示
nnoremap <silent> [unite]r :<C-u>Unite register<CR>
nnoremap <silent> [unite]v :<C-u>VimFilerBufferDir -explorer -toggle -no-quit<CR>
nnoremap <silent> [unite]o :<C-u>Uo<CR>
"MattesGroeger/vim-bookmarksを開く
nnoremap <silent> [unite]kk :<C-u>Unite vim_bookmarks<CR>
"Unite bookmarkを開く
nnoremap <silent> [unite]k  :<C-u>Unite bookmark<CR>
"Uniteのbookmarkに追加 ~/.unite/bookmark/default に格納
nnoremap <silent> [unite]ab :<C-u>UniteBookmarkAdd<CR>
"全体に適応 end    ###############################################

"vimfiler ##################
"vimデフォルトのエクスプローラをvimfilerで置き換える
let g:vimfiler_as_default_explorer = 1
"セーフモードを無効にした状態で起動する
let g:vimfiler_safe_mode_by_default = 0

"autocmd VimEnter * VimFilerExplorer
autocmd FileType vimfiler nmap <buffer> <Leader>uv <Plug>(vimfiler_close)

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

:command! -nargs=? Uss call s:Unite_session_save(<f-args>)
:function! s:Unite_session_save(...)
: if a:0 >= 1
:   let hogearg = a:1
:   echo "UniteSessionSave ".hogearg
:   execute 'UniteSessionSave ' . a:1
: else
:   echo "UniteSessionSave ".g:unite_source_session_default_session_name
:   execute 'UniteSessionSave '.g:unite_source_session_default_session_name
: end
:endfunction
"セッションを保存 enc    ##

"セッションを上書き保存
command! Usos call s:Unite_session_override_save()
function! s:Unite_session_override_save()
   let filepath = v:this_session
    if filepath  == ''
        let filepath = g:unite_source_session_default_session_name
    endif

   let filename = fnamemodify(filepath, ":t:r")
   let inputtext = input("save current session? "."session_name=".filename." y or n ")
      redraw
   if inputtext == 'y'
      echo "UniteSessionSave ".filename
      execute 'UniteSessionSave ' .filename
   else
      echo "canceled save current session. session_name=".filename
   endif
":   let answer = confirm('save current session? '.filename, "&Yes\n&No", 1)
":   if answer == 1
":      echo "UniteSessionSave ".filename
":      execute 'UniteSessionSave ' .filename
":    endif
": end
:endfunction

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

"unite out-line start ##########################################################
:command! -nargs=? Uo call s:Unite_outline(<f-args>)
:function! s:Unite_outline(...)
: if a:0 >= 1
:   let hogearg = a:1
:   execute 'Unite -winheight=' . a:1.' outline'
: else
:   echo "Unite outline"
:   execute "Unite -winheight=10 outline"
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

"bronson/vim-trailing-whitespace start #########################################
let g:extra_whitespace_ignored_filetypes = ['unite', 'mkd']
:highlight ExtraWhitespace ctermbg=darkgreen guibg=lightgreen
nnoremap fws :<C-u>FixWhitespace<Leader><CR>
"bronson/vim-trailing-whitespace end   #########################################

"ctrlp start ###################################################################
nnoremap [ctrlp]    <Nop>
nmap     <Leader>c [ctrlp]
nnoremap [ctrlp]p :<C-u>CtrlP<Leader>
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
"cnnoremap [ctrlp]trlp end   ###################################################################

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
let g:auto_ctags = 1
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
  GitGutterNextHunk
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
      return
    endif
  endwhile
endfunction

function! PrevHunkAllBuffers()
  let line = line('.')
  GitGutterPrevHunk
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
      return
    endif
  endwhile
endfunction
"airblade/vim-gitgutter   end   ###################################################################

"rhysd/clever-f.vim ##################################################
let g:clever_f_smart_case = 1
"rhysd/clever-f.vim ##################################################

"deris/vim-gothrough-jk  ##################################################
let g:gothrough_jk_go_step = 5
"deris/vim-gothrough-jk  ##################################################

"Plug 'easymotion/vim-easymotion' start ##################################################
let g:EasyMotion_do_mapping = 0 " Disable default mappings
let g:EasyMotion_smartcase = 1

nnoremap [easymotion]    <Nop>
nmap . [easymotion]

map [easymotion] <Plug>(easymotion-prefix)

" <Leader>f{char} to move to {char}
map  [easymotion]f <Plug>(easymotion-bd-f)
nmap [easymotion]f <Plug>(easymotion-overwin-f)
" Turn on case insensitive feature

" s{char}{char} to move to {char}{char}
" Jump to anywhere you want with minimal keystrokes, with just one key binding.
" `s{char}{label}`
"nmap s <Plug>(easymotion-overwin-f)
" or
" `s{char}{char}{label}`
" Need one more keystroke, but on average, it may be more comfortable.
nmap s <Plug>(easymotion-overwin-f2)

" Gif config
"nmap s <Plug>(easymotion-s2)
"nmap t <Plug>(easymotion-t2)

" Gif config
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)

" These `n` & `N` mappings are options. You do not have to map `n` & `N` to EasyMotion.
" Without these mappings, `n` & `N` works fine. (These mappings just provide
" different highlight method and have some other features )
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)

" Move to line
map [easymotion]L <Plug>(easymotion-bd-jk)
nmap [easymotion]L <Plug>(easymotion-overwin-line)

" JK motions: Line motions
map [easymotion]l <Plug>(easymotion-lineforward)
map [easymotion]j <Plug>(easymotion-j)
map [easymotion]k <Plug>(easymotion-k)
map [easymotion]h <Plug>(easymotion-linebackward)

" Move to word
map  [easymotion]w <Plug>(easymotion-bd-w)
nmap [easymotion]w <Plug>(easymotion-overwin-w)
"Plug 'easymotion/vim-easymotion' end  ##################################################

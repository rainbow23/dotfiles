set number
set showmatch
set matchtime=1
set autoindent
set shiftwidth=4
set tabstop=4
syntax on
set hlsearch
"set termguicolors nvim用
"set nohlsearch
"set cursorline
"highlight Normal ctermbg=black ctermfg=white
highlight StatusLine term=none cterm=none ctermfg=black ctermbg=grey
"highlight CursorLine term=none cterm=none ctermfg=none ctermbg=grey

call plug#begin('~/.vim/plugged') 
"Plug 'junegunn/seoul256.vim'
Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle'] }
Plug 'junegunn/vim-easy-align'
Plug 'Shougo/unite.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
"Plug 'powerline/fonts'
"Plug 'ctrlpvim/ctrlp.vim'
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'
Plug 'Shougo/neocomplcache.vim'
"Plug 'majutsushi/tagbar'
"Plug 'JuliaLang/julia-vim', { 'for': ['julia'] }
"Plug 'zah/nim.vim', { 'for': ['nim'] }
"Plug 'rust-lang/rust.vim', { 'for': ['rust'] }
"Plug 'melrief/vim-frege-syntax', { 'for': ['frege'] }
call plug#end()

"EasyAlign start #####################################################################
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
"EasyAlign end  #####################################################################

"NERDTree start #####################################################################
nnoremap <silent><C-T> :NERDTreeToggle<CR>
nnoremap <C-H> :noh <CR>
let g:NERDTreeShowBookmarks=1
nnoremap <C-N> :bnext<CR>
nnoremap <C-P> :bprevious<CR>
nnoremap <C-X> :bdelete<CR>
nmap <Leader>b :CtrlPBuffer<CR>
"NERDTree end   #####################################################################

"vim-airline start #####################################################################
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme='badwolf'
let g:airline#extensions#syntastic#enabled = 1
"let g:airline#extensions#tabline#left_sep = ' '
"let g:airline#extensions#tabline#left_alt_sep = '|'
set laststatus=2
set t_Co=256 "vim-air-line-themeを反映させる
"vim-airline end  #####################################################################

" x:削除でヤンクしない
nnoremap x "_x
nnoremap dd "_dd

"改行後INSERT MODEにしない
nnoremap O :<C-u>call append(expand('.'), '')<Cr>j
"nnoremap O o<Esc>

"ノーマルモード＋ビジュアルモード
noremap <C-j> <Esc>
"コマンドラインモード＋インサートモード
noremap! <C-j> <Esc>

"neosnippets start #####################################################################
"plugin key-mappings.
imap <c-k>     <plug>(neosnippet_expand_or_jump)
smap <c-k>     <plug>(neosnippet_expand_or_jump)
xmap <c-k>     <plug>(neosnippet_expand_target)

let g:neosnippet#snippets_directory='~/.vim/plugged/neosnippet-snippets/neosnippets'
"起動時に有効
let g:neocomplete#enable_at_startup=1
let g:neocomplcache_enable_at_startup=1
"ポップアップメニューで表示される候補の数
let g:neocomplete#max_list = 50
"キーワードの長さ、デフォルトで80
let g:neocomplete#max_keyword_width=80
let g:neocomplete#enable_ignore_case=1
highlight Pmenu ctermbg=6
highlight PmenuSel ctermbg=3
highlight PMenuSbar ctermbg=0

"inoremap <expr><CR>  pumvisible() ? neocomplete#close_popup() : “<CR>”
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


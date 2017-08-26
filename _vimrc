set number
set showmatch
set matchtime=1
set autoindent
set shiftwidth=4
set tabstop=4
syntax on
set hlsearch
"set nohlsearch
set cursorline
"highlight Normal ctermbg=black ctermfg=white
"highlight StatusLine term=none cterm=none ctermfg=black ctermbg=grey
"highlight CursorLine term=none cterm=none ctermfg=none ctermbg=grey


call plug#begin('~/.vim/plugged') 
Plug 'junegunn/seoul256.vim'

Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle'] }

Plug 'junegunn/vim-easy-align'

"Plug 'tpope/vim-fireplace', { 'for': ['clojure'] }

"Plug 'JuliaLang/julia-vim', { 'for': ['julia'] }

"Plug 'zah/nim.vim', { 'for': ['nim'] }

"Plug 'rust-lang/rust.vim', { 'for': ['rust'] }

"Plug 'rhysd/vim-crystal', { 'for': ['crystal'] }

"Plug 'melrief/vim-frege-syntax', { 'for': ['frege'] }
call plug#end()

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

nnoremap <silent><C-N> :NERDTreeToggle<CR>
nnoremap <C-H> :noh <CR>


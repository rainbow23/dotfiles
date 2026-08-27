-- 設定不要（または g: 変数のみで動く）プラグイン群
-- 大きな設定を持つプラグインは plugins/ 配下の個別ファイルを参照
return {
  -- FZF
  { 'junegunn/vim-easy-align',   lazy = false },
  { 'junegunn/fzf',     dir = '~/.fzf', build = './install --bin', lazy = false },
  { 'junegunn/fzf.vim', lazy = false, dependencies = { 'junegunn/fzf' } },
  { 'junegunn/vim-peekaboo',     lazy = false },
  -- UI
  { 'vim-airline/vim-airline',        lazy = false },
  { 'vim-airline/vim-airline-themes', lazy = false },
  { 'Yggdroot/indentLine',            lazy = false },
  { 'itchyny/vim-cursorword',         lazy = false },
  { 'itchyny/vim-parenmatch',         lazy = false },
  { 'machakann/vim-highlightedyank',  lazy = false },
  -- Clipboard / Yank
  { 'kana/vim-fakeclip',         lazy = false },
  { 'leafcage/yankround.vim',    lazy = false },
  -- Cursor / Motion
  { 'terryma/vim-multiple-cursors',  lazy = false },
  { 'rhysd/accelerated-jk',         lazy = false },
  { 'easymotion/vim-easymotion',     lazy = false },
  { 'rhysd/clever-f.vim',            lazy = false },
  { 'yuttie/comfortable-motion.vim', lazy = false },
  -- Search
  { 'rainbow23/vim-anzu',        lazy = false },
  { 'mileszs/ack.vim',           lazy = false },
  { 'thinca/vim-qfreplace',      lazy = false },
  { 't9md/vim-quickhl',          lazy = false },
  -- File / Buffer
  -- NERDTree 系は plugins/nerdtree.lua（設定は config/nerdtree.lua）を参照
  { 'jlanzarotta/bufexplorer',        lazy = false },  -- 設定は config/bufexplorer.lua
  { 'christoomey/vim-tmux-navigator', lazy = false },
  -- Git
  { 'tpope/vim-fugitive',          lazy = false },
  { 'tpope/vim-rhubarb',           lazy = false },
  { 'airblade/vim-gitgutter',      lazy = false },
  { 'iberianpig/tig-explorer.vim', lazy = false },
  { 'rbgrouleff/bclose.vim',       lazy = false },
  -- Edit
  { 'preservim/nerdcommenter',          lazy = false },
  { 'machakann/vim-sandwich',           lazy = false },
  { 'tpope/vim-surround',               lazy = false },
  { 'tpope/vim-repeat',                 lazy = false },
  { 'jiangmiao/auto-pairs',             lazy = false },
  { 'ntpeters/vim-better-whitespace',   lazy = false },
  { 'kana/vim-operator-user',           lazy = false },
  { 'kana/vim-operator-replace',        lazy = false, dependencies = { 'kana/vim-operator-user' } },
  -- Snippet
  { 'rainbow23/vim-snippets', lazy = false },
  -- Go
  { 'fatih/vim-go', build = ':GoUpdateBinaries', lazy = false },
  -- JSON / HTML
  { 'elzr/vim-json',      lazy = false },
  { 'alvan/vim-closetag', lazy = false },
  -- Util
  { 'majutsushi/tagbar', lazy = false },
}

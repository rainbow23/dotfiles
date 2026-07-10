-- 設定不要（または g: 変数のみで動く）プラグイン群
-- 大きな設定を持つプラグインは plugins/ 配下の個別ファイルを参照
return {
  -- FZF
  { 'junegunn/vim-easy-align',   lazy = false },
  { 'junegunn/fzf',     dir = '~/.fzf', build = './install --bin', lazy = false },
  { 'junegunn/fzf.vim', lazy = false, dependencies = { 'junegunn/fzf' } },
  { 'junegunn/vim-peekaboo',     lazy = false },
  -- Unite
  { 'Shougo/unite.vim',          lazy = false },
  { 'rainbow23/unite-session',   lazy = false },
  { 'Shougo/neomru.vim',         lazy = false },
  { 'Shougo/unite-outline',      lazy = false },
  { 'Shougo/vimproc.vim',        build = 'make', lazy = false },
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
  { 'yuki-yano/fuzzy-motion.vim',    lazy = false },
  { 'rhysd/clever-f.vim',            lazy = false },
  { 'yuttie/comfortable-motion.vim', lazy = false },
  { 'matze/vim-move',                lazy = false },
  -- Search
  { 'rainbow23/vim-anzu',        lazy = false },
  { 'mileszs/ack.vim',           lazy = false },
  { 'thinca/vim-qfreplace',      lazy = false },
  { 't9md/vim-quickhl',          lazy = false },
  -- File / Buffer
  { 'preservim/nerdtree',             lazy = false },
  { 'jistr/vim-nerdtree-tabs',        lazy = false },
  { 'Xuyuanp/nerdtree-git-plugin',    lazy = false },
  { 'jlanzarotta/bufexplorer',        lazy = false, init = function() vim.g.bufExplorerDisableDefaultKeyMapping = 1 end },
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
  { 'fatih/vim-go',        build = ':GoUpdateBinaries', lazy = false },
  { 'mdempsky/gocode',     rtp = 'vim', lazy = false },
  { 'mattn/vim-goimports', lazy = false },
  -- JSON / HTML
  { 'elzr/vim-json',      lazy = false },
  { 'alvan/vim-closetag', lazy = false },
  -- Util
  { 'majutsushi/tagbar',          lazy = false },
  { 'tyru/current-func-info.vim', lazy = false },
  -- ZoomWin は float window 実装（rc/zoom.lua）に置き換えたため削除済み
  { 'vimlab/split-term.vim',      lazy = false },
  { 'osyo-manga/unite-quickfix',  lazy = false },
  { 'ujihisa/unite-colorscheme',  lazy = false },
  -- Denops plugins
  { 'Shougo/deol.nvim',                    lazy = false },
  { 'vim-denops/denops.vim',               lazy = false },
  { 'vim-denops/denops-shared-server.vim', lazy = false },
  { 'vim-denops/denops-helloworld.vim',    lazy = false },
  { 'lambdalisue/kensaku.vim',             lazy = false },
  { 'lambdalisue/kensaku-search.vim',      lazy = false },
  { 'vim-skk/skkeleton',                   lazy = false },
}

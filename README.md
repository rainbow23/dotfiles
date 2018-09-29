どのOSでもvim設定を同じにする目的でリポジトリを作った
git clone後に./init.shを実行

tmux paneでカーソルドラッグ&ドロップでコピーする方法  
iterms > Preferences > ON: Applications in terminal may access clipboard

tmux-resurrect https://github.com/tmux-plugins/tmux-resurrect

1 セッション、ウインドウのフォルダ階層、パネル、パネル表示文字を保存、復元するプラグインを入れた  
2 既存バグ：セッション名とウインドウ名が同じだと復元されない  
3 回避方法：セッション名をウインドウ名と違う名前にする  
4 vim sessionを復元するリポジトリも追加 https://github.com/tmux-plugins/tmux-resurrect/blob/master/docs/restoring_vim_and_neovim_sessions.md

tmux-resurrectを動作させた時の問題  
1 復元時bash3.2の名前になる(MAC)  
2 解決：.bashrcに修正を記載 export PS1='\h:\W \u\$ '   
3 tmuxコマンドを実行したら.bashrcを読むように指定する alias tmux='~/.bashrc'

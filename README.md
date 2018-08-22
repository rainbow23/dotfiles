どのOSでもvim設定を同じにする目的でリポジトリを作った

使い方
1 ユーザールートディレクトリでこのリポジトリをpullする　dotfiles ディレクトリができる

2 シンボリックファイルを作成　ln -s ~/dotfiles/_vimrc ~/.vimrc
  シンボリックフォルダを作成  ln -s ~/dotfiles/vimrepos ~/.vim
  
3 viでvimplugプラグインのインストールコマンドを実行
　例　vi ~/.vimrc 
 　　:PlugInstall   
参考にしたurl: http://holypp.hatenablog.com/entry/20110515/1305443997


tmux-resurrect https://github.com/tmux-plugins/tmux-resurrect

1 セッション、ウインドウのフォルダ階層、パネル、パネル表示文字を保存、復元するプラグインを入れた

2 既存バグ：セッション名とウインドウ名が同じだと復元されない

3 回避方法：セッション名をウインドウ名と違う名前にする

4 vim sessionを復元するリポジトリも追加 https://github.com/tmux-plugins/tmux-resurrect/blob/master/docs/restoring_vim_and_neovim_sessions.md



tmux-resurrectを動作させた時の問題

1 復元時bash3.2の名前になる(MAC)

2 解決：.bashrcに修正を記載 export PS1='\h:\W \u\$ ' 

3 tmuxコマンドを実行したら.bashrcを読むように指定する alias tmux='~/.bashrc'

4 .bashrcもdotfilesフォルダに追加、シンボリックファイルを作る　ln -s ~/dotfiles/.bashrc ~/.bashrc

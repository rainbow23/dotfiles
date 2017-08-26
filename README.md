どのOSでもvim設定を同じにする目的でリポジトリを作った

使い方
1 ユーザールートディレクトリでこのリポジトリをpullする　dotfiles ディレクトリができる

2 シンボリックファイルを作成　ln -s ~/dotfiles/_vimrc ~/.vimrc
  シンボリックフォルダを作成  ln -s ~/dotfiles/vimrepos ~/.vim
  
3 viでvimplugプラグインのインストールコマンドを実行
　例　vi ~/.vimrc 
 　　:PlugInstall
   
参考にしたurl: http://holypp.hatenablog.com/entry/20110515/1305443997

#! /bin/bash

# パスまとめ
STEAMHOME=/home/steam
STEAMCMD_PATH=$STEAMHOME/steamcmd
INSTALL_DIR=../ark

# 必要なライブラリをインストールする
yum -y install glibc.i686 glibc-devel.i686 libstdc++.i686 wget expect systemd systemd-sysv

# ユーザーを一度削除し、再度追加する
useradd -m steam

# SteamCMD のディレクトリを作成し、移動する
mkdir $STEAMCMD_PATH
cd $STEAMCMD_PATH

# SteamCMD をダウンロードする
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz

# 展開する
tar -xvzf steamcmd_linux.tar.gz

# 必要の無いファイルの削除
rm -rf steamcmd_linux.tar.gz

# ユーザ権限変更
chown steam. /home/steam -R

# steamcmd.sh を実行する
expect -c "
set timeout -1
spawn sh $STEAMCMD_PATH/steamcmd.sh
expect \"Steam>\" ; send \"login anonymous \r\"
expect \"Steam>\" ; send \"force_install_dir $INSTALL_DIR \r\"
expect \"Steam>\" ; send \"app_update 376030 validate \r\"
expect \"Steam>\" ; send \"exit \r\"
"
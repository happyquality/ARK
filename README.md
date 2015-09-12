# Ark survival evolved -サーバ建築-

- - -

** Ark survival evolved ** のLinux版メモ

[TOC]

- - -
### 0.今回のサーバ状態

今回は、下記要件のサーバにインストール！

- 要件
> OS : CentOS7
> メモリ : 8G
> OSインストール方法
> - GNOME Desktop
> - 互換性ライブラリ、開発ツール、セキュリティツール
> <p>にチェックが入った状態
> <p>
> 状態：インストールしただけのまっさらな状態

この要件以外の場合、必要に合わせて取捨選択してください

- - -
### 1.初期情報
|ポートタイプ|ポート番号|              Purpose            |
|----------|--------|---------------------------------|
|   UDP   |  27015 |    steamのサーバブラウザ用のポート   |
|   UDP   |  27016 |    steamのサーバブラウザ用のポート   |
|   UDP   |  7777  |    ゲームクライアントで使用するポート   |
|   TCP   |  32330 |リモートコンソールにアクセスするためのRCON|

参考URL<p>
[SteamCMD Install](https://developer.valvesoftware.com/wiki/SteamCMD#Linux)<p>
[ARK Server Setup](http://ark.gamepedia.com/Dedicated_Server_Setup)

- - -
### 2.開くファイルの最大数を変更する
この設定を行わないと、ファイルの最大展開数をオーバーする可能性がある

``/etc/sysclt.conf``に追加する
```
fs.file-max=100000
```

変更をかけたら、適応する
```
sysctl -p /etc/sysctl.conf
```

``/etc/security/limits.conf``に追加する
```
* soft nofile 1000000
* hard nofile 1000000
```

- - -
### 3.SteamCMD のインストール

StreamCMD をインストールするためのシェルスクリプト
<p> この操作は、Root権限で行うようにしてください


- 必要なライブラリをインストールする
```
yum -y install glibc.i686 glibc-devel.i686 libstdc++.i686 wget expect
```

- ユーザーを追加する
```
useradd -m steam
```

- SteamCMD のディレクトリを作成し、移動する
```
mkdir /home/steam/steamcmd
cd /home/steam/steamcmd
```

- SteamCMD をダウンロードする
```
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
```

- 展開する
```
tar -xvzf steamcmd_linux.tar.gz
```

- 必要の無いファイルの削除
```
rm -rf steamcmd_linux.tar.gz
```

- ユーザ権限変更
```
chown steam. /home/steam -R
```

これで
```
/home/steam/steamcmd
```
ここに、steam の実行スクリプトなどが置かれました。
展開内容は
```
linux32/
steam.sh
steamcmd.sh
```
の３つが展開されているはずです。

- - -
### 4.steamCMD を使用し、データをダウンロードする
<p>
ここに移動する
```
cd /home/steam/steamcmd
```
<p>
実行するシェルスクリプトは、``steamcmd.sh``なので
```
sh steamcmd.sh
```
と実行する

初回起動や更新があった場合、まずそれが走るので``Steam> ``と出るまで待つ

```
Steam> login anonymous
Steam> force_install_dir <install_dir>
Steam> app_update 376030 validate
Steam> exit
```
``<install_dir>``には、steamからダウンロードしてくるファイルを置くディレクトリを指定する<p>
無いディレクトリを指定した場合、作成される

- - -
### 5.サーバセッティング
サーバの実行スクリプトを``server_start.sh``という名前で作成する
```
#! /bin/bash
./ShooterGameServer TheIsland?listen?SessionName=<server_name>
?ServerPassword=<join_password>?ServerAdminPassword=<admin_password> -server -log
```
↑長いので改行してあります。実際には、１行になります。<p>
``<server_name>``ゲームサーバ用の名前を任意で変更<p>
``<join_password>``ゲームサーバにアクセスするためのパスワード<p>
``<admin_password>``ゲームサーバの管理者アクセスを得るために設定する<p>
ゲームサーバにアクセスする際のパスワードが必要ない場合
``?ServerPassword=<join_password>``をまるまる消す<p>

``./ShooterGameServer``これの場所は、
```
<SteamCMDを使用してダウンロードを行った際に指定したディレクトリ>/ShooterGame/Binaries/Linux/ShooterGameServer
```
でしたが、実際の場所は個々で確認を行うようにしてください

作成が完了したら
```
chomd +x server_start.sh
```
で、実行権限を付与する


- - -
### 6.自動起動設定

**サーバ起動時に自動的に起動する設定を行うことが推奨されています。**

``/etc/systemd/system/ark-dedicated.service`` を作成する
```
[Unit]
Description=ARK: Survival Evolved dedicated server
Wants=network-online.target
After=syslog.target network.target nss-lookup.target network-online.target

[Service]
ExecStart=/home/steam/servers/ark/ShooterGame/Binaries/Linux/ShooterGameServer TheIsland?listen?SessionName=<SESSION_NAME> -server -log
LimitNOFILE=100000
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
User=steam
Group=steam

[Install]
WantedBy=multi-user.target
```
``ExecStart``サービスを開始するために実行するコマンドを設定します。実行するコマンドの指定はフルパスでおこないます。
サーバセッティング欄で記載した、起動スクリプトに指定している引数を使用することができます。

最後の２箇所 ``User`` ``Group`` で実行時のユーザとグループ設定を変更します。この起動設定を抜くと、rootユーザとして実行されますが、ゲームサーバからリモートでスーパーユーザーのアクセスを得る攻撃に繋がる可能性があり、安全ではありません。

この目的のためだけに使用権限のないアカウントでサーバを起動することをお勧めします。上記の例では、ユーザアカウント "steam" が使用されています。正確には、アカウントと一緒に作成された "steam" グループのメンバーです。

これから行う処理には、systemctl を使用しますので、
```
yum install systemd systemd-sysv
```
が入っていることが前提となります。
インストール後は、サーバの再起動が必要となります。
(CentOS7ではデフォルトで入っています。)

サーバ起動時の実行を許可します。
```
systemctl enable ark-dedicated
```

ゲームサーバを実行します。
```
systemctl start ark-dedicated
```

#### セットアップ後の管理

実行中のゲームサーバを停止します。
```
systemctl stop ark-dedicated
```

ゲームサーバのステータス状態を表示します。
```
systemctl status ark-dedicated
```

設定ファイル ``ark-dedicated.service`` に変更をかけた場合、次のコマンドを実行します
```
systemctl daemon-reload
```


- - -

### 最後に
自分が設定を行う際に用意したスクリプトを置いておきます。

- Setup.sh
SteamCMDをインストールし、ゲームをダウンロードを行うまでのスクリプト

- ark-dedicated.service
/etc/systemd/system 内に置くスクリプトになります。


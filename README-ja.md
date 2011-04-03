rnbo
====================


DESCRIPTION
--------------------
rnboは、東京電力の計画停電情報を提供して下さっている
[計画停電カレンダー](https://sites.google.com/a/creco.net/teiden-calendar/)の
内容に基き、ReadyNAS NV+(以下ReadyNASとも)の電源オン/オフスケジュールを設
定するプログラムです。

ReadyNAS自身がカレンダーを参照し、自分自身の起動終了時刻の設定変更を行う
点が特徴です。


PLATFORM
--------------------
サポートしているOSは以下の通りです。

- ReadyNAS NV+(NETGEAR製)

他ReadyNASシリーズでの動作は未確認です。


WARNING
--------------------
本プログラムの利用にあたっては以下の点へご注意下さい。

本プログラムは
[計画停電カレンダー](https://sites.google.com/a/creco.net/teiden-calendar/)
に依存しています。本プログラムの利用に当たっては、計画停電カレンダーに関
する制限事項に関してもご留意ください。

計画停電カレンダーはボランティアの方々によって運営されている非公式なサー
ビスです。東京電力による当日の変更発表などは反映されず、またデータフォー
マットが変更になる可能性もあります。変更発表のタイミングやフォーマットの
変更内容によっては、本プログラムは適切にスケジュールを設定が出来ない可能
性があります。

計画停電カレンダー運営グループに対し、本プログラムに関する問い合わせを行
うことはご遠慮下さい。

本プログラムの利用にあたっては
[Enable Root SSH アクセス](http://www.readynas.com/ja/?p=3492)Addonの
インストールが必要です。このAddonをインストールした場合、NETGEAR社
によるサポートが拒否される場合がありますのでご注意ください。

Web管理画面の「システム」->「電源」->「パワータイマー」から設定できる電源
のオン・オフ設定と排他的な利用になります。「パワータイマー」の利用が必要
な場合には、本プログラムを利用することは出来ません。

本プログラムは完全無保証です。スクリプトのインストールや、スケジュールの
設定間違い、電源のオン/オフ失敗などに起因するデータ消失などに関しては、自
己責任にてお願いいたします。


PREPARATION
--------------------
本プログラムの利用にあたっては、ReadyNASに対し、以下の準備が必要です。

[Enable Root SSH アクセス](http://www.readynas.com/ja/?p=3492)Addonを
インストールしていない場合にはインストールしてください。但し、上記
WARNINGで述べたように、このAddonをインストールした場合、NETGEAR社によるサ
ポートが拒否される場合がありますのでご注意ください。

インターネットからデータを取得できるようにReadyNAS の設定を行なって下さい。
例えば固定IPアドレスで運用している場合には、Web管理画面の「ネットワー
ク」->「グローバル設定」内にある「デフォルト・ゲートウェイ」と「DNS設定」
が正しく行われていることを確認して下さい。

現在時刻を正しく設定して下さい。特にWeb管理画面の「システム」->「時計」か
ら辿れる「タイムゾーンの指定」が「GMT+09:00 東京、大阪、札幌」に設定されている
ことを確認して下さい。


INSTALL
--------------------

本プログラムはReadyNAS上で動作するため、ReadyNAS上へインストールする必要
があります。

インストールには「インストールスクリプトを使う方法」と「手動で行う方法」
とがあります。お好きな方法を選択してください。

以下の説明に於いては次の環境を仮定しています。

- ReadyNASのホスト名はnas
- 計画停電のグループは1a
- プログラムの動作がエラーとなった場合、admin@example.com へメイル伝達する

また%はMac(またはインストール処理を実行している機器)のコマンドプロンプト
を、#はnasへログインした際のコマンドプロンプトを示します。


### スクリプトでインストール

scp / ssh / shellスクリプトを使える環境が必要です。MacOS X 10.6 での動作
のみを確認しています。

installer.sh、rhp.sh、rnbo.pl ファイルの揃っているディレクトリで、

    % sh ./installer.sh nas install 1a admin@example.com

と実行します。引数は順番に、「ReadyNAS NV+のホスト名」「install」、「計画
停電のグループ」、「エラー発生時に伝達して欲しいメイルアドレス」です。

途中2回ほど nas の root パスワードが聞かれます。Webコンソールから admin
としてログインする際に使用しているパスワードを入力してください。

実行中の処理を表示しながらプログラムのインストールが行われ、5、8、11、14、
17時の適当な「分」に、電源オン/オフスケジュールの確認と更新を行うように設
定されます。

インストール終了後、最新のカレンダー情報を取得しに行きます。

以下はコマンドの実行例です。

    % ./installer.sh nas install 1a admin@example.com
    root@nas's password:
    rnbo.pl                                       100% 9225     9.0KB/s   00:00
    rhp.sh                                        100% 4041     4.0KB/s   00:00
    root@nas's password:
    [ -e /etc/cron.d/poweroff ] && mv /etc/cron.d/poweroff /etc/cron.d/poweroff.rnbo
    touch /etc/cron.d/poweroff
    chown admin:admin /etc/cron.d/poweroff
    [ -e /etc/frontview/poweron_timer ] && mv /etc/frontview/poweron_timer /etc/frontview/poweron_timer.rnbo
    touch /etc/frontview/poweron_timer
    chown admin:admin /etc/frontview/poweron_timer
    install -o admin -g admin -S.rnbo rnbo.pl /sbin/rnbo.pl
    echo "08 5,8,11,14,17 * * * root /sbin/rnbo.pl -a admin@example.com 1a &> /dev/null" > /etc/cron.d/rnbo
    chown admin:admin /etc/cron.d/rnbo
    nohup /sbin/rnbo.pl 1a &> /dev/null &

以上で終了です。


### 手動でインストール

scp / ssh を使える環境が必要です。MacOS X 10.6 での動作のみを確認していま
す。

rnbo.plをReadyNASの任意の場所へscpします。コピーの際、nas の root パスワー
ドが聞かれます。Webコンソールから admin としてログインする際に使用してい
るパスワードを入力してください。例えば/ramfsへコピーする場合には、以下の
通りです。

    % scp rnbo.pl root@nas:/ramfs/
    root@nas's password:

nas へ ssh で login します。パスワードは先ほどと同じです。

    % ssh root@nas
    root@nas's password:
    #

予めインストールされている poweron / poweoff 用の設定ファイルをバックアッ
プしておくと良いでしょう。

    # mv /etc/cron.d/poweroff /etc/cron.d/poweroff.rnbo
    # mv /etc/frontview/poweron_timer /etc/frontview/poweron_timer.rnbo

scp でコピーした rnbo.pl を適当な場所へ cp します。例えば /sbin へcp する
場合には、以下の通りです。

    # install -o admin -g admin /ramfs/rnbo.pl /sbin/rnbo.pl

rnbo.pl を自動起動するように corn を設定します。crontab を /etc/cron.d/
へ格納するとよいでしょう。

なお、起動時刻の設定にあたっては、カレンダーサイトへ負荷の掛からないよう
に適切な時刻を選択して下さい。例えば、不必用に短いタイミングでアクセスを
繰り返すことは避ける、確認を行う「分」は、多くの方が設定しそうな時刻を避
ける、などに留意すると良いでしょう。

rhbo.pl の最終引数には、自身の計画停電グループを指定します。サブグループ
も含めて指定可能です。またrnbo.plのエラー発生時、メイルでその旨を伝達させ
たい場合には -a オプションとメイルアドレスを指定します。

例えば、

- 5、8、11、14、17時の08分に確認を行う
- 計画停電グループは1a
- エラー発生時、admin@example.com へメイルで伝達する

場合には、以下の通りです。

    # echo "08 5,8,11,14,17 * * * root /sbin/rnbo.pl -a admin@example.com 1a &> /dev/null" > /etc/cron.d/rnbo
    # chown admin:admin /etc/cron.d/rnbo

最後に rnbo.pl を起動して poweron / poweroff 用の設定ファイルを更新します。

    # /sbin/rnbo.pl 1a &> /dev/null

更新処理終了後 nas から exit します。

    # exit


UNINSTALL
--------------------

本プログラムが不要になった場合には、アンインストールして下さい。以下の説
明に於いて、ReadyNAS のホスト名を nas とします。


### スクリプトでアンインストール

この方法は「スクリプトでインストール」を行った場合にのみ利用可能です。イ
ンストール時にバックアップした元ファイルを復元し、インストールしたファイ
ルを削除します。

installer.sh、rhp.sh ファイルの揃っているディレクトリで、

    % ./installer.sh nas uninstall

と実行します。引数は順番に「ReadyNAS NV+のホスト名」「uninstall」です。

途中2回ほど nas の root パスワードが聞かれます。インストール時同様、適切
なパスワードを入力してください。

以下はコマンドの実行例です。

    % sh ./installer.sh nas uninstall
    root@nas's password:
    rhp.sh                                        100% 4041     4.0KB/s   00:00
    root@nas's password:
    rm /etc/cron.d/rnbo
    rm /sbin/rnbo.pl
    mv /etc/cron.d/poweroff.rnbo /etc/cron.d/poweroff
    mv /etc/frontview/poweron_timer.rnbo /etc/frontview/poweron_timer


### 手動でアンインストール

ssh を使える環境が必要です。

nas へ ssh で login します。

    % ssh root@nas
    root@nas's password:
    #

インストールした crontab ファイルを削除します。

    # rm /etc/cron.d/rnbo

インストールした rnbo.pl を削除します。

    # rm /sbin/rnbo.pl

poweron / poweoff 用の設定ファイルをバックアップしてある場合には、それら
を復元します。

    # mv /etc/cron.d/poweroff.rnbo /etc/cron.d/poweroff
    # mv /etc/frontview/poweron_timer.rnbo /etc/frontview/poweron_timer

exit して終了です。

    # exit


OPTION
--------------------

rnbo.pl起動時の引数は以下の通りです。

    rnbo.pl [OPTION] group

group には計画停電グループを数値で指定します。サブグループを指定する場合
には、数値に続けて、aからeまでのアルファベットを指定します。例えば1グルー
プの場合は「1」を、5グループのeサブグループの場合には「5e」を指定します。

オプションには以下を指定可能です。

-a <ADMINADDR>  
エラーが発生した際に報告するメイルアドレス指定します。オプションが無指定
の場合、標準エラー出力へ書き出されます。

-c <COMMAND>  
shutdown 時に実行したいコマンドを指定します。デフォルト値は標準の
poweroff コマンドです。

-d <DIFF>  
計画停電の時刻と、実際に powerdown、poweron を行うまでの時間差を秒で指定
します。指定された秒数分、停電開始時刻よりも早く powerdown を行い、停電終
了時刻から指定された秒数経過した後 poweron を行います。デフォルト値は300
秒です。

-s <SHUTDOWNFILE>  
poweroff に関する情報を書き出すファイル名を指定します。書き出しはcorntab
形式です。SHUTDOWNFILE として '-' を指定した場合、標準出力へ書き出されま
す。書き出しが不要な場合には /dev/null を指定してください。デフォルト値は、
ReadyNASの標準poweroffファイルです。

-t <TIMEOUT>  
計画停電カレンダーへアクセスする際のタイムアウト値を秒で指定します。この
秒数が経過しても計画停電カレンダーサーバから応答がない場合には、取得を諦
めます。デフォルト値は30秒です。

-w <WAKEUPFILE>  
poweron に関する情報を書き出すファイル名を指定します。書き出しは、
ReadyNAS NV+ の独自形式です。WAKEUPFILE として '-' を指定した場合、標準出
力へ書き出されます。書き出しが不要な場合には /dev/null を指定してください。
デフォルト値は、ReadyNASの標準poweronファイルです。


EXAMPLES
--------------------
1a グループとして設定させたい場合には:

    # perl rnbo.pl 1a

3グループとして、poweron 情報を /ramfs/pon へ、poweoff 情報を
/ramfs/poff へ出力し、エラー発生時にadmin@example.jp へメッセージを伝達さ
せたい場合には:

    # perl rnbo.pl -w /ramfs/pon -s /ramfs/poff -a admin@example.jp 3

5eグループとして、タイムアウト値を10秒、定刻との差分1分(60 秒)、shutdown
時に実行するコマンドを /sbin/poweroff として設定させたい場合には:

    # perl rnbo.pl -t 10 -d 60 -c /sbin/poweroff 5e


SPECIAL THANKS
--------------------
計画停電カレンダーを立ち上げてくださり、利用を許可してくださった
@shinagaki さんへ感謝いたします。

また、同カレンダを維持管理してくださっているメインテナの方々へ感謝いたし
ます。


AUTHOR
--------------------
MIYOKAWA, Nobuyoshi

* E-Mail: n-miyo@tempus.org
* Twitter: nmiyo
* Blog: http://blogger.tempus.org/
* Facebook: http://www.facebook.com/nobuyoshi.miyokawa


COPYRIGHT
--------------------
Copyright (c) 2010-2011 MIYOKAWA, Nobuyoshi.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHORS ''AS IS'' AND ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

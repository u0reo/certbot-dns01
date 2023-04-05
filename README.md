# Certbot with DNS-01

DockerでDNSサーバーを立ち上げ、dns-01チャレンジを行えます。  
Be able to run DNS-01 challenge by launching a DNS server on Docker.

[![dockeri.co](https://dockerico.blankenship.io/image/ureo/certbot-dns01)](https://hub.docker.com/r/ureo/certbot-dns01)

## 参考<br/>Reference

[Let’s Encryptでワイルドカード証明書を取得する話 | IIJ Engineers Blog](https://eng-blog.iij.ad.jp/archives/14198)


## 動作確認済み環境<br/>Operation confirmed environment

- DS218play
- Raspberry Pi4 (4GB)

## 必須要件<br/>Requiredments

- DNSSEC署名済みドメイン  
  DNSSEC signed domain
- 外から53ポートでアクセスできるネットワーク環境  
  Network environment that can access 53 ports from the outside

## 環境変数<br/>Environmental Variables

- DOMAIN  
  ex) example.com
- ADDR  
  ex) 2001:db8::1
- EMAIL  
  ex) letsencrypt@example.com
- TEST (for certbot)  
  ex) true

## ボリューム<br/>Volumes

- /etc/letsencrypt (for certbot)
- /config (for knot dns)
- /rundir (for knot dns)
- /storage (for knot dns)
- /certificate (for dsm only)  
  <- /usr/syno/etc/certificate

## サンプルコマンド<br/>Sample Command

```shell
sudo docker run --rm -i --net host \
-e DOMAIN=example.com \
-e ADDR=2001:db8::1 \
-e EMAIL=letsencrypt@example.com \
--name certbot-dns01 \
-v certbot_data:/etc/letsencrypt \
-v knot_config:/config \
-v knot_rundir:/rundir \
-v knot_storage:/storage \
-v /usr/syno/etc/certificate:/certificate \
ureo/certbot-dns01:0.1 ./script.sh
```

## 手順<br/>Procedure

※ サンプルコマンドの環境変数を使うため、適宜読み替えてください

NOTE: Please read as appropriate to use the environment variable in the sample command

1. `acme.example.com` に `2001:db8::1` を設定する  
   Set `2001:db8::1` to `acme.example.com`

2. `_acme-challenge.example.com` にNS(CNAME)レコードを `acme.example.com` 向けで設定  
   Set `acme.example.com` as NS (CNAME) record to `_acme-challenge.example.com`

3. `2001:db8::1` の 53ポートを開放  
   Open 53 ports of `2001:db8::1`

4. `docker run --rm ... ./init.sh`

5. 出力を _acme-challenge.example.com にDSレコードとして設定  
   Set output as DS record to `_acme-challenge.example.com`

6. `docker run --rm ... ./first.sh`

7. 生成された証明書をDSMに設定 (on DSM only)  
   Set the generated certificate to DSM (on DSM only)

8. `docker create ... ./renew.sh`

9. 以下のコマンドを定期的に実行  
   Execute the following commands regularly
   `docker start certbot-dns01 -ai`

## 定期実行のコマンド例<br/>Regular execution command example

### Synology NAS

```shell:synology.sh
synofirewall --disable &&
docker start certbot-dns01 -ai &&
synosystemctl restart nginx &&
synofirewall --enable
```

## トラブルシューティング<br/>Trouble Shooting

### DSレコードが正しく設定されていない<br/>DS record is not set correctly

#### エラー例<br/>Error Examples

```
DNS problem: SERVFAIL looking up TXT for _acme-challenge.example.com - the domain's nameservers may be malfunctioning
```

```
DNS problem: query timed out looking up TXT for _acme-challenge.example.com
```

```
Encountered error when making query: The DNS operation timed out.
```

#### 解決方法<br/>Solution

手順の1から4を再度実行する  
Execute 1 to 4 of the procedure again

または次の実行結果を比較し、合わない場合は前者でとれたDSレコードを設定し、再度実行  
Or compare the following execution results, set the DS record that is removed in the former if it does not fit, and execute it again.

```shell
# 出力: 本来設定されるべきDSレコード
# Output: DS record that should be set
docker run -rm ... ./get_ds.sh
```

```shell
# 出力: 現在ネームサーバーに設定されているDSレコード
# Output: DS record currently set on the name server
docker run -rm ... kdig acme.example.com ds
```


### Docker上にのKnot DNSに外からアクセスできない<br/>Cannot access to Knot DNS on Docker from outside

#### エラー例<br/>Error Example

```
Encountered exception during recovery: certbot.errors.PluginError: Unable to determine base domain for _acme-challenge.example.com using names: ['_acme-challenge.example.com', 'example.com', 'com'].
```

#### 解決方法<br/>Solution

NAS等のシステムのファイアウォール、ルーターのポート解放、そしてアドレス等を再度確認する。  
Check the firewalls of NAS and other systems, release routers, and address again.

次のコマンドを実行することでDNSサーバーを一時的に立てることができるため、その間に外からアクセスできるかを確かめる。
By executing the following command, you can temporarily stand the DNS server, so that you can access from the outside in the meantime.

```shell
docker run --rm ... sh -c "knotd -d && sleep 3600 && knotc stop"
```


### DSレコード登録の送信失敗<br/>Submitting DS record registration failed

#### エラー例<br/>Error Example

```
Submitting DS Record Registration...error: [_acme-challenge.example.com] (no key ready for submission)
```

#### 解決方法<br/>Solution

多くの場合は既にacme.example.comのDSレコードを設定し、それをKnot DNSに通知済みなだけなので、最後の証明書発行後にinit.shを実行していなければ無視してOK  
In many cases, the DS record of acme.example.com has already been set, and it has only been notified to Knot DNS, so if you do not execute init.sh after issuing the last certificate, you can ignore it.

# Certbot with DNS-01

DockerでDNSサーバーを立ち上げ、dns-01チャレンジを行えます。  
Be able to run DNS-01 challenge by launching a DNS server on Docker.

## 参考</br>Reference

[Let’s Encryptでワイルドカード証明書を取得する話 | IIJ Engineers Blog](https://eng-blog.iij.ad.jp/archives/14198)


## 動作確認済み環境</br>Operation confirmed environment

- DS218play
- Raspberry Pi4 (4GB)

## 必須要件</br>Requiredments

- DNSSEC署名済みドメイン  
  DNSSEC signed domain
- 外から53ポートでアクセスできるネットワーク環境  
  Network environment that can access 53 ports from the outside

## 環境変数</br>Environmental Variables

- DOMAIN  
  ex) example.com
- ADDR  
  ex) 2001:db8::1
- EMAIL  
  ex) letsencrypt@example.com
- TEST (for certbot)  
  ex) true

## ボリューム</br>Volumes

- /etc/letsencrypt (for certbot)
- /config (for knot dns)
- /rundir (for knot dns)
- /storage (for knot dns)
- /certificate (for dsm only)  
  <- /usr/syno/etc/certificate

## サンプルコマンド</br>Sample Command

```
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
certbot-dns01:0.1 ./script.sh
```

## 手順</br>Procedure

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

```
synofirewall --disable
docker start certbot-dns01 -ai
synosystemctl reload nginx
synofirewall --enable
```

#!/bin/sh
yum install socat -y
#安装acme.sh
sudo curl https://get.acme.sh | sh
sudo alias acme.sh=~/.acme.sh/acme.sh
sudo echo 'alias acme.sh=~/.acme.sh/acme.sh' >>/etc/profile

sudo acme.sh --force --issue --standalone -d test.xxqing.cn
#00 00 * * * root /root/.acme.sh/acme.sh --cron --home /root/.acme.sh &>/var/log/acme.sh.logs
#先创建用于存放证书的文件夹
sudo mkdir -p /etc/nginx/ssl_cert/test.xxqing.cn

sudo acme.sh --force --install-cert -d test.xxqing.cn \
--key-file /etc/nginx/ssl_cert/test.xxqing.cn/test.xxqing.cn.key \
--fullchain-file /etc/nginx/ssl_cert/test.xxqing.cn/test.xxqing.cn.cer \
--reloadcmd  "service nginx force-reload"

#配置nginx
sudo cd /etc/nginx/conf.d

sudo echo "server {
    listen 443 ssl http2;
    server_name test.xxqing.cn;
    root /opt/jar/web;
    ssl_certificate       /etc/nginx/ssl_cert/test.xxqing.cn/test.xxqing.cn.cer;
    ssl_certificate_key   /etc/nginx/ssl_cert/test.xxqing.cn/test.xxqing.cn.key;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers TLS13-AES-128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;


    location /api {
        proxy_pass http://127.0.0.1:9091/;
    }

    location /ws/ {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 80;
    server_name test.xxqing.cn;
    return 301 https://\$http_host/\$request_uri;
}" > v2ray-manager.conf

sudo nginx -s reload

#!/bin/bash
IP="65.21.249.105"

rm ~/.ssh/known_hosts

ssh root@$IP <<EOF
apt update
apt install snapd -y
snap install core
snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
certbot certonly --standalone
openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048

apt install curl gnupg2 ca-certificates lsb-release
echo "deb http://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | tee /etc/apt/preferences.d/99nginx
curl -o /tmp/nginx_signing.key https://nginx.org/keys/nginx_signing.key
gpg --dry-run --quiet --import --import-options show-only /tmp/nginx_signing.key
mv /tmp/nginx_signing.key /etc/apt/trusted.gpg.d/nginx_signing.asc
apt update
apt install nginx -y
EOF
scp server/nginx.conf root@$IP:/etc/nginx/nginx.conf
ssh root@$IP <<EOF
nginx -s reload

curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
apt install -y nodejs
npm install -g npm@latest
npm install -g pm2@latest 
pm2 startup

ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw enable

apt update
apt full-upgrade -y
apt autoclean
apt autoremove
apt clean
EOF
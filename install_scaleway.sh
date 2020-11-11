#! /bin/bash

ufw default deny
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && dpkg -i erlang-solutions_2.0_all.deb
apt-get update
apt-get install -y git certbot esl-erlang elixir

# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
apt-get install -y git certbot esl-erlang elixir apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt update
apt-cache policy docker-ce
apt install docker-ce

wget 'https://caddyserver.com/api/download?os=linux&arch=amd64&idempotency=57616987570201' -O caddy
chmod +x caddy

mix local.hex --force
mix local.rebar --force
mix archive.install --force hex phx_new

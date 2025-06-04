#!/bin/bash

sudo yum update -y
sudo yum install -y docker
sudo yum install -y git

sudo yum install -y nfs-utils

sudo systemctl start docker
sudo systemctl enable docker

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

cd / 

sudo mkdir -p /mnt/efs

sudo mount -t nfs4 -o nfsvers=4.1 DNSAQUI:/ /mnt/efs

sudo docker volume create \
  --driver local \
  --opt type=none \
  --opt device=/mnt/efs/wordpress \
  --opt o=bind \
  wp-efs

sudo mkdir projeto-compass
cd projeto-compass

sudo git clone https://github.com/Thullyoo/Compass-UOL-Projeto-2.git
cd Compass-UOL-Projeto-2

echo "DB_URL=seuendpointaqui" | sudo tee .env > /dev/null

sudo docker-compose up -d


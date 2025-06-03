#!/bin/bash

echo "DB_URL=" > .env

sudo yum update -y

sudo yum install -y docker

sudo service docker start

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

cd /

sudo mkdir projeto-compass
 
cd projeto-compass

sudo yum install -y git

sudo git clone https://github.com/Thullyoo/Compass-UOL-Projeto-2.git

cd Compass-UOL-Projeto-2

sudo docker-compose up
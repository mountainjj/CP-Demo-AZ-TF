#!/bin/bash
sudo apt-get update -y &&
sudo apt-get install -y \
apt-transport-https \
ca-certificates \
curl
gnupg-agent\
software-properties-common &&
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
sudo add-apt-repository "deb [arch-and64] https://download.docker.com/linux/ubuntu $(1sb_release -cs) stable" &&
sudo apt-get update -y &&
sudo sudo apt-get install docker-ce docker co-cli containerd.io -y &&
sudo usermod -6 docker ubuntu
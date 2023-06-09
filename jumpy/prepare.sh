#!/bin/bash

echo "Configure vim"
touch ~/.vimrc
echo "syntax on" > ~/.vimrc
echo "colorscheme elflord" > ~/.vimrc
echo "set number" > ~/.vimrc

echo ""
echo "Configure git"
git config --global user.name "Sebastián Greco"
git config --global core.editor vim
git config --global fetch.prune false
git config --global pull.merge true
git config --global pull.rebase false
git config --global diff.colorMoved zebra

echo ""
echo "Prepare os"
sudo apt update

echo ""
echo "Install terraform"
sudo apt install software-properties-common gnupg2 curl -y
curl https://apt.releases.hashicorp.com/gpg | gpg --dearmor > hashicorp.gpg
sudo install -o root -g root -m 644 hashicorp.gpg /etc/apt/trusted.gpg.d/
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt install terraform -y
terraform -install-autocomplete
rm -rf hashicorp.gpg

echo ""
echo "Install ansible"
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt install ansible -y

echo ""
echo "Generate core user ssh key"
ssh-keygen -t rsa -b 4096 -C "core" -f ~/.ssh/core -N ""

echo ""
echo "Install kubectl"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update
apt install kubectl -y

#!/usr/bin/bash

set -eux

apt-get update

locale-gen en_US.UTF-8
localectl set-locale LANG=en_US.UTF-8

echo "StreamLocalBindUnlink yes" >> /etc/ssh/sshd_config
systemctl restart sshd

su -c "source /vagrant/scripts/user.sh" vagrant

docker build -t signing /home/vagrant


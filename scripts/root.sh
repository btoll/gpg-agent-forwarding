#!/usr/bin/bash

apt-get update
apt-get install -y \
    apt-file \
    debsigs \
    devscripts \
    dh-make \
    nginx \
    reprepro \
    rng-tools \
    tree

locale-gen en_US.UTF-8
localectl set-locale LANG=en_US.UTF-8

cp /vagrant/default /etc/nginx/sites-available/default
systemctl restart nginx

su -c "source /vagrant/scripts/user.sh" vagrant


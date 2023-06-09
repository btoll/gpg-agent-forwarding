# -*- mode: ruby -*-
# vi: set ft=ruby :
#

Vagrant.configure("2") do |config|
    config.vm.box =  "debian/bullseye64"
    config.vm.hostname = "debian-bullseye"
    config.vm.network :public_network, ip: "192.168.1.200", bridge: "wlp3s0"

    config.vm.provider "virtualbox" do |vb|
        vb.memory = 8192
        vb.name = "signing"
    end

    config.vm.provision :shell do |s|
        s.path = "scripts/root.sh"
        s.env = {
            PACKAGE_NAME: ENV["PACKAGE_NAME"],
            PACKAGE_VERSION: ENV["PACKAGE_VERSION"],
        }
    end
end


#!/usr/bin/bash

set -eux

# We must import the public key first or signing won't work.
# The agent forwarding will work, but the private key bits
# won't be in the keyring.
gpg --no-default-keyring \
    --keyring /home/vagrant/.gnupg/pubring.kbx \
    --import /vagrant/public.key

echo no-autostart >> /home/vagrant/.gnupg/gpg.conf
# We don't need to copy the public key to the VM since we
# just imported it into the VM's keyring.
# We could, of course, but I like the idea of only having
# to copy the original key once.
gpg --export > pub.key

cp /vagrant/{Dockerfile,build_deb.sh} .

# This will be the directory that is bind-mounted into the container
# and in which the build artifacts will be after running.
mkdir build


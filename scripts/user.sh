#!/usr/bin/bash

# Copy over the configs and build script to create the
# APT repository and packages, respectively.
mkdir /home/vagrant/base
cp -r /vagrant/conf /home/vagrant/base
cp -r /vagrant/build.sh /home/vagrant

# These env vars will be needed by `build.sh` in the VM.
cat << EOF >> /home/vagrant/package_env
PACKAGE_NAME="$PACKAGE_NAME"
PACKAGE_VERSION="$PACKAGE_VERSION"
EOF

chown vagrant:vagrant /home/vagrant/package_env

# We must import the public key first or signing won't work.
# The agent forwarding will work, but the private key bits
# won't be in the keyring.
gpg --no-default-keyring \
    --keyring /home/vagrant/.gnupg/pubring.kbx \
    --import /vagrant/public.key

KEYID=$(gpg \
    --show-keys \
    --keyid-format long \
    /vagrant/public.key \
    | grep "\[S\]" \
    | sed -n 's/.*rsa[0-9]*\/\([A-Z0-9]*\).*/\1/p')

# Create the directories and copy in the public key that the `debsigs`
# tool needs.
sudo mkdir -p "/usr/share/debsig/keyrings/$KEYID/"
sudo cp /vagrant/public.key "/usr/share/debsig/keyrings/$KEYID/debsig.gpg"

# `debsig-verify` needs the below policy to be able to verify the
# signatures created by debsigs.
sudo mkdir -p "/etc/debsig/policies/$KEYID/"

cat << EOF | sudo tee "/etc/debsig/policies/$KEYID/sign.pol"
<?xml version="1.0"?>
<!DOCTYPE Policy SYSTEM "https://www.debian.org/debsig/1.0/policy.dtd">
<Policy xmlns="https://www.debian.org/debsig/1.0/">

<Origin Name="asbits" id="$KEYID" Description="asbits package"/>

<Selection>
<Required Type="origin" File="debsig.gpg" id="$KEYID"/>
</Selection>

<Verification MinOptional="0">
<Required Type="origin" File="debsig.gpg" id="$KEYID"/>
</Verification>
</Policy>
EOF


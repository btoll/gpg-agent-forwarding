#!/usr/bin/bash

set -euxo pipefail

apt-get update
apt-get install -y \
    debsigs \
    devscripts \
    dh-make \
    openssh-server

#locale-gen en_US.UTF-8
#localectl set-locale LANG=en_US.UTF-8

echo "StreamLocalBindUnlink yes" >> /etc/ssh/sshd_config
/etc/init.d/ssh start

curl -LO /path/to/public.key
gpg --import public.key

KEYID=$(gpg \
    --show-keys \
    --keyid-format=long \
    public.key \
    | grep "\[S\]" \
    | sed -n 's/.*rsa[0-9]*\/\([A-Z0-9]*\).*/\1/p')

# Create the directories and copy in the public key that the `debsigs` tool needs.
mkdir -p "/usr/share/debsig/keyrings/$KEYID/"
cp /public.key "/usr/share/debsig/keyrings/$KEYID/debsig.gpg"


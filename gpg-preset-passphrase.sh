#!/usr/bin/bash

set -eux

# This will target the signing subkey.
KEYGRIP=$(gpg --list-secret-keys --with-keygrip \
    | grep -A1 "[S]" \
    | tail -1 \
    | awk '{print $3}')

gpg-connect-agent /bye
"$(gpgconf --list-dirs libexecdir)/gpg-preset-passphrase" --preset "$KEYGRIP"
gpg-connect-agent "keyinfo --list" /bye


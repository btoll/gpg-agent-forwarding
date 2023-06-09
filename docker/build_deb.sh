#!/bin/bash
# shellcheck source=/dev/null
# https://www.shellcheck.net/wiki/SC1091

set -euxo pipefail

DEB="${PACKAGE_NAME}_${PACKAGE_VERSION}_amd64.deb"
BUILDDIR="$HOME/build/${PACKAGE_NAME}-${PACKAGE_VERSION}"

if [ ! -d "$BUILDDIR" ]
then
    # `git-clone` will create the nested directory structure.
    git clone "https://github.com/btoll/$PACKAGE_NAME.git" "$BUILDDIR"
fi

cd "$BUILDDIR"

# The following will get the long id from the list of secret keys.
# Specifically, the `sed` command will parse this:
#
#       ssb   rsa4096/3A1314344B0D9912 2023-06-04 [S]
#
KEYID=$(gpg --list-secret-keys --keyid-format=long \
    | grep "\[S\]" \
    | sed -n 's/.*rsa[0-9]*\/\([A-Z0-9]*\).*/\1/p')

# Build both the binary and source packages and sign both.
# This signs the `InRelease` file and creates a detached signature in the binary package.
# This signs the `.dsc` and `.changes` files of the source package.
dpkg-buildpackage \
	--build=source,any,all \
	--force-sign \
	--root-command=fakeroot \
	--sign-key="$KEYID"

debsigs --sign=origin -k "$KEYID" "../$DEB"


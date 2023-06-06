#!/usr/bin/bash
# shellcheck source=/dev/null
# https://www.shellcheck.net/wiki/SC1091

set -eux

trap cleanup EXIT

cleanup() {
    rm -rf "$TMPDIR"
}

# Bring the environments written to this file in the Vagrantfile
# into this session.
. package_env

# Remove the following lines when not testing.
set +e
reprepro --basedir /home/vagrant/base remove bullseye "$PACKAGE_NAME" 2> /dev/null
set -e

DEB="${PACKAGE_NAME}_${PACKAGE_VERSION}_amd64.deb"
DSC="${PACKAGE_NAME}_${PACKAGE_VERSION}.dsc"
TMPDIR=$(mktemp -d)
BUILDDIR="$TMPDIR/${PACKAGE_NAME}-${PACKAGE_VERSION}"
# The following will get the long id from the list of secret keys.
# Specifically, the `sed` command will parse this:
#
#       ssb   rsa4096/3A1314344B0D9912 2023-06-04 [S]
#
KEYID=$(gpg --list-secret-keys --keyid-format long | grep "\[S\]" | sed -n 's/.*rsa[0-9]*\/\([A-Z0-9]*\).*/\1/p')

# git-clone will create the directory structure if it doesn't exist.
git clone "https://github.com/btoll/$PACKAGE_NAME.git" "$BUILDDIR"

cd "$BUILDDIR"

# Build both the binary and source packages and sign both.
# This signs the `InRelease` file and creates a detached signature in the binary package.
# This signs the `.dsc` and `.changes` files of the source package.
dpkg-buildpackage \
	--build=source,any,all \
	--force-sign \
	--root-command=fakeroot \
	--sign-key="$KEYID"

debsigs --sign=origin -k "$KEYID" "../$DEB"
sudo debsig-verify "../$DEB"

# Import both the binary and source packages into the repository.
reprepro --basedir /home/vagrant/base includedeb bullseye "../$DEB"
reprepro --basedir /home/vagrant/base includedsc bullseye "../$DSC"


#!/usr/bin/bash

# https://www.shellcheck.net/wiki/SC1091
# shellcheck source=/dev/null

set -euxo pipefail

# Install Docker Engine.
# https://docs.docker.com/engine/install/debian/
# ----------------------
# Update the apt package index and install packages to allow apt to use a
# repository over HTTPS.
apt-get update && \
apt-get install -y \
    ca-certificates \
    curl \
    gnupg

# Add Docker’s official GPG key.
curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /usr/share/keyrings/docker.gpg
chmod a+r /usr/share/keyrings/docker.gpg

# Use the following command to set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine, containerd, and Docker Compose.
apt-get update && \
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin


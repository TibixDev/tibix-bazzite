#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# Some RPM installations expect this directory to exist in bootc builds.
mkdir -p /var/lib/alternatives

# Universal Blue setup hooks used by the Docker group provisioning below.
dnf5 install \
    --enable-repo="copr:copr.fedorainfracloud.org:ublue-os:packages" \
    -y \
    ublue-setup-services

# Packages inherited from the shared image plus Tibix-specific additions.
dnf5 install -y \
    android-tools \
    binutils \
    code \
    containerd.io \
    darkly \
    dmg2img \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    dwarfs \
    flatpak-builder \
    fsearch \
    git-lfs \
    klassy \
    libusb1-devel \
    libxkbcommon \
    perf \
    python3-vkbasalt-cli \
    qdirstat \
    qemu-audio-dbus \
    qemu-ui-dbus \
    rsms-inter-fonts \
    sysprof \
    systemd-devel \
    telnet \
    uv \
    virt-viewer \
    zsh \
    zsh-autosuggestions \
    zerotier-one

# dotool reloads host devices in its RPM scripts; install it for an offline image.
/ctx/dotool/install.sh

# ngrok does not publish a versioned v3 archive at this endpoint. This keeps
# the behavior of the previous image and follows ngrok's stable v3 release.
wget \
    --hsts-file /tmp/.wget-hsts \
    --output-document /tmp/ngrok.tar.gz \
    https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
mkdir /tmp/ngrok-install
tar -xf /tmp/ngrok.tar.gz -C /tmp/ngrok-install
install -Dm0755 /tmp/ngrok-install/ngrok /usr/bin/ngrok

# Standalone upstream RPMs, pinned and verified before installation.
curl --fail --location --retry 3 --output /tmp/amdgpu_top.rpm \
    https://github.com/Umio-Yasuno/amdgpu_top/releases/download/v0.11.5/amdgpu_top-0.11.5-1.x86_64.rpm
curl --fail --location --retry 3 --output /tmp/lsfg-vk.rpm \
    https://github.com/PancakeTAS/lsfg-vk/releases/download/v1.0.0/lsfg-vk-1.0.0.x86_64.rpm
sha256sum --check <<'EOF'
ef224f5d1c8e7621a2f309c3d465d05a18c4c660d48da5edc215c7c4e6d53e71  /tmp/amdgpu_top.rpm
77749bbd5bddd19ea38b090e0cec8912e9285a92b9345429df924dc33cc47786  /tmp/lsfg-vk.rpm
EOF
dnf5 install -y /tmp/amdgpu_top.rpm /tmp/lsfg-vk.rpm

# Screenshot application, desktop permissions, and KDE shortcut integration.
/ctx/lumine-capture/install.sh

systemctl enable docker.socket
systemctl enable podman.socket
systemctl enable zerotier-one.service
systemctl enable ublue-system-setup.service
systemctl --global enable ublue-user-setup.service

# Required for Docker-in-Docker and devcontainers.
cat >/etc/modules-load.d/ip_tables.conf <<'EOF'
iptable_nat
EOF

dnf5 clean all

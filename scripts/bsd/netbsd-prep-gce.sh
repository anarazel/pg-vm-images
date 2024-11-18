#!/bin/sh

set -e

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/pkg/bin:/usr/pkg/sbin

# Network
cat > /etc/ifconfig.vioif0 << EOF
!dhcpcd vioif0
mtu 1460
EOF

# Install curl for startup & shutdown scripts
PKG_PATH="http://cdn.NetBSD.org/pub/pkgsrc/packages/NetBSD/$(uname -p)/$(uname -r|cut -f '1 2' -d.)/All/" && \
export PKG_PATH && \
pkg_add pkgin && \
echo $PKG_PATH > /usr/pkg/etc/pkgin/repositories.conf && \
pkgin update && \
pkgin upgrade -y && \
pkgin -y install \
    curl

# Install sudo and then set its configuration to 'users can access sudo without password'
pkgin -y install sudo
echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo

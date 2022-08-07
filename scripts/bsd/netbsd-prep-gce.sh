#!/bin/sh

# Network
cat > /etc/ifconfig.vioif0 << EOF
!dhcpcd vioif0
mtu 1460
EOF

# Install curl for startup & shutdown scripts
PKG_PATH="http://cdn.NetBSD.org/pub/pkgsrc/packages/NetBSD/$(uname -p)/$(uname -r|cut -f '1 2' -d.)/All/" && \
export PKG_PATH && \
/usr/sbin/pkg_add pkgin && \
/usr/pkg/bin/pkgin update && \
/usr/pkg/bin/pkgin upgrade -y && \
/usr/pkg/bin/pkgin -y install \
    curl \
    mozilla-rootcerts && \
/usr/pkg/sbin/mozilla-rootcerts install

# Forbid root username/password login
/usr/bin/sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config

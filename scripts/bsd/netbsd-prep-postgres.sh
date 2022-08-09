#!/bin/sh

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/pkg/bin:/usr/pkg/sbin

# Install required packages for running tests on netBSD
pkgin -y install \
    vim \
    git \
    gmake \
    gettext \
    meson \
    bison \
    ccache \
    p5-IPC-Run \
    flex \
    pkgconf \
    python39 \
    icu \
    lz4 \
    libxslt \
    tcl \
    zstd

# Set kernel parameters for running postgres tests
echo "sysctl -w kern.ipc.semmni=2048" >> /etc/rc.local
echo "sysctl -w kern.ipc.semmns=32768" >> /etc/rc.local

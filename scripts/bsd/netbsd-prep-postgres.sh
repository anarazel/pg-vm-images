#!/bin/sh

set -e

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
    docbook-xml \
    gnupg \
    p5-IPC-Run \
    p5-Module-Signature \
    flex \
    pkgconf \
    python312 \
    py312-cryptography \
    py312-packaging \
    py312-pip \
    py312-test \
    icu \
    lz4 \
    libxslt \
    mit-krb5 \
    tcl \
    zstd

echo "alias python3=python3.12" >> ~/.bashrc
echo "alias pip3=pip3.12" >> ~/.bashrc
echo "alias pytest=pytest-3.12" >> ~/.bashrc

# Set kernel parameters for running postgres tests
echo "sysctl -w kern.ipc.semmni=2048" >> /etc/rc.local
echo "sysctl -w kern.ipc.semmns=32768" >> /etc/rc.local

# Generate more verbose boot logs, helpful for debugging
awk '/Boot normally/ {
    new=$0;
    sub(/normally/, "verbose", new);
    sub(/boot$/, "boot -v", new);
    print new;
}
{ print }
' /boot.cfg > /boot.cfg.new && mv /boot.cfg.new /boot.cfg

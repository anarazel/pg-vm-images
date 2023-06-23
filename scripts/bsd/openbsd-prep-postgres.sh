#!/bin/sh

pkg_add -I \
    vim--no_x11 git \
    bash \
    git \
    gmake \
    meson \
    pkgconf \
    \
    bison \
    ccache \
    gettext-tools \
    \
    p5-IPC-Run \
    \
    icu4c \
    libxml \
    libxslt \
    lz4 \
    openpam \
    python%3.9 \
    readline \
    tcl%8.6 \
    zstd \
    \
    login_krb5 \
    openldap-client--gssapi \
    openldap-server--gssapi
python3 -m ensurepip --upgrade

#####
# Add 'noatime' and 'softdep' to the mount points
# https://man.openbsd.org/mount.8
FSTAB_FILE=/etc/fstab
OPTIONS='noatime,softdep'

cat ${FSTAB_FILE}
echo "Enabling mount option(s) \"${OPTIONS}\""
sed -i -e "/ffs/  s/rw/rw,${OPTIONS}/" ${FSTAB_FILE}
cat ${FSTAB_FILE}
#####

# Set kernel parameters for running postgres tests
echo "/sbin/sysctl kern.seminfo.semmni=2048" >> /etc/rc.local
echo "/sbin/sysctl kern.seminfo.semmns=32768" >> /etc/rc.local

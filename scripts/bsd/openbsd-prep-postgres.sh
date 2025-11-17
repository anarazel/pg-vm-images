#!/bin/sh

set -e

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
    gnupg \
    p5-IPC-Run \
    p5-Module-Signature \
    \
    docbook \
    icu4c \
    libxml \
    libxslt \
    lz4 \
    openpam \
    python%3 \
    readline \
    tcl%8.6 \
    zstd \
    \
    login_krb5 \
    openldap-client--gssapi \
    openldap-server--gssapi

# Upgrade the IPC::Run version to latest.
export MODULE_SIGNATURE_KEYSERVER=pgpkeys.eu
(
 echo;                            # automate first-time setup
 echo o conf check_sigs 1;        # check signatures
 echo o conf init gpg; echo;      # use the default path for gpg
 echo o conf recommends_policy 0; # don't install "recommended" modules
 echo notest install IPC::Run;
) | cpan

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
echo "/sbin/sysctl kern.maxfiles=10000" >> /etc/rc.local

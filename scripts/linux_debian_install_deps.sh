#! /bin/sh

set -e

export DEBIAN_FRONTEND=noninteractive

apt-get -y install --no-install-recommends \
  procps \
  \
  build-essential \
  gdb \
  git \
  make \
  meson \
  perl \
  pkg-config \
  \
  bison \
  ccache \
  clang \
  clang-16 \
  flex \
  g++ \
  gcc \
  gettext \
  python3-pip \
  \
  libio-pty-perl \
  libipc-run-perl \
  python3-setuptools \
  \
  libicu-dev \
  libkrb5-*-heimdal \
  libkrb5-dev \
  libldap2-dev \
  liblz4-dev \
  libossp-uuid-dev \
  libpam-dev \
  libperl-dev \
  libpython3-dev \
  libreadline-dev \
  libselinux*-dev \
  libssl-dev \
  libsystemd-dev \
  liburing-dev \
  libxml2-dev \
  libxslt1-dev \
  libzstd-dev \
  llvm-16-dev \
  llvm-dev \
  systemtap-sdt-dev \
  tcl-dev \
  uuid-dev \
  \
  docbook-xml \
  docbook-xsl \
  fop \
  libxml2-utils \
  pandoc \
  wget \
  xsltproc \
  \
  lcov \
  \
  krb5-admin-server \
  krb5-kdc \
  krb5-user \
  ldap-utils \
  locales-all \
  lz4 \
  slapd \
  zstd \
  \
  g++-mingw-w64-x86-64-win32 \
  gcc-mingw-w64-x86-64-win32 \
  libz-mingw-w64-dev \
  mingw-w64-tools

if [ $(dpkg --print-architecture) = "amd64" ] ; then

  # Install development packages necessary to target i386 from amd64. Leave
  # out packages that'd enlarge the image unduly (e.g. llvm-dev).
  #
  # Not installing libossp-uuid-dev:i386, systemtap-sdt-dev:i386
  # they conflict with the amd64 variants
  dpkg --add-architecture i386
  apt-get update
  apt-get -y install --no-install-recommends --no-remove \
    gcc-multilib \
    \
    libicu-dev:i386 \
    libkrb5-*-heimdal:i386 \
    libkrb5-dev:i386 \
    libldap2-dev:i386 \
    liblz4-dev:i386 \
    libpam-dev:i386 \
    libperl-dev:i386 \
    libpython3-dev:i386 \
    libreadline-dev:i386 \
    libselinux*-dev:i386 \
    libssl-dev:i386 \
    libsystemd-dev:i386 \
    liburing-dev:i386 \
    libxml2-dev:i386 \
    libxslt1-dev:i386 \
    libzstd-dev:i386 \
    tcl-dev:i386 \
    uuid-dev:i386
fi

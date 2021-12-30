#! /bin/sh

set -e

export DEBIAN_FRONTEND=noninteractive

apt-get -y install --no-install-recommends \
  procps \
  \
  build-essential \
  gdb \
  make \
  git \
  meson \
  perl \
  pkg-config \
  \
  bison \
  ccache \
  clang \
  flex \
  g++ \
  gcc \
  gettext \
  \
  libio-pty-perl \
  libipc-run-perl \
  python3-distutils \
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
  llvm-dev \
  python3-dev \
  systemtap-sdt-dev \
  tcl-dev \
  uuid-dev \
  \
  docbook-xml \
  docbook-xsl \
  fop \
  libxml2-utils \
  xsltproc \
  \
  krb5-admin-server \
  krb5-kdc \
  krb5-user \
  ldap-utils \
  locales-all \
  slapd \
  \
  g++-mingw-w64-x86-64-win32 \
  gcc-mingw-w64-x86-64-win32 \
  libz-mingw-w64-dev

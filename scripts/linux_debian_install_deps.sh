#! /bin/bash
# -*-indent-tabs-mode: nil; -*-

set -e

export DEBIAN_FRONTEND=noninteractive


temp_ver=$(cat /etc/debian_version)
case "$temp_ver" in
  sid|*/sid)
    # Set version to 999 for Debian Sid, this is helpful for comparing
    # version numbers
    MAJOR_DEBIAN_VERSION=999
    ;;
  *)
    MAJOR_DEBIAN_VERSION=$(echo "$temp_ver" | cut -d. -f1)
  ;;
esac

if [ "$MAJOR_DEBIAN_VERSION" -lt 12 ]; then
  echo "Oldest supported Debian release is 'bookworm'"
  exit 1
fi

# Collect list of packages in an array and then install later, makes it easier
# to add comments and conditionallity
packages=()

# Generic sysadmin stuff that's useful for timing, debugging etc
packages+=(
    gdb
    procps
    time
)

# Basic build tools
packages+=(
    build-essential
    git
    make
    meson
    perl
    pkg-config
)

# Compilers, build-time tooling
packages+=(
    bison
    ccache
    flex
    g++
    gcc
    gettext
    python3-pip
)

# Compilers for building with LLVM support
packages+=(
    clang
    '?exact-name(clang-16)'
)

# Basic test dependencies
packages+=(
    gnupg
    libio-pty-perl
    libipc-run-perl
    libmodule-signature-perl
    python3-cryptography
    python3-packaging
    python3-pytest
    python3-setuptools
)

# Compile time library dependencies
packages+=(
    libcurl4-openssl-dev
    libicu-dev
    libkrb5-*-heimdal
    libkrb5-dev
    libldap2-dev
    liblz4-dev
    libnuma-dev
    libossp-uuid-dev
    libpam-dev
    libperl-dev
    libpython3-dev
    libreadline-dev
    libselinux-dev
    libssl-dev
    libsystemd-dev
    liburing-dev
    libxml2-dev
    libxslt1-dev
    libzstd-dev
    '?name(llvm-16-dev)'
    llvm-dev
    systemtap-sdt-dev
    tcl-dev
    uuid-dev
)

# Full test dependencies
packages+=(
  krb5-admin-server
  krb5-kdc
  krb5-user
  ldap-utils
  locales-all
  lz4
  slapd
  zstd
)

# Cross building windows
packages+=(
  libz-mingw-w64-dev
  mingw-w64-tools
)

# g++-mingw-w64-x86-64-win32 and gcc-mingw-w64-x86-64-win32 packages have
# missing some functions in the headers starting from trixie, install ucrt64
# versions on these releases.
if [ "$MAJOR_DEBIAN_VERSION" -lt "13" ] ; then
    packages+=(
        g++-mingw-w64-x86-64-win32
        gcc-mingw-w64-x86-64-win32
    )
else
    packages+=(
	g++-mingw-w64-ucrt64
        gcc-mingw-w64-ucrt64
    )
fi

if [ $(dpkg --print-architecture) = "amd64" ] ; then

  # Install development packages necessary to target i386 from amd64. Leave
  # out packages that'd enlarge the image unduly (e.g. llvm-dev).
  #
  # Not installing libossp-uuid-dev:i386, systemtap-sdt-dev:i386
  # they conflict with the amd64 variants
  dpkg --add-architecture i386
  apt-get update

  packages+=(
      gcc-multilib

      libcurl4-openssl-dev:i386
      libicu-dev:i386
      libkrb5-*-heimdal:i386
      libkrb5-dev:i386
      libldap2-dev:i386
      liblz4-dev:i386
      libpam-dev:i386
      libperl-dev:i386
      libpython3-dev:i386
      libreadline-dev:i386
      libselinux-dev:i386
      libssl-dev:i386
      libsystemd-dev:i386
      liburing-dev:i386
      libxml2-dev:i386
      libxslt1-dev:i386
      libzstd-dev:i386
      tcl-dev:i386
      uuid-dev:i386
  )
fi

apt-get -y install --no-install-recommends "${packages[@]}"


echo "packages installed, performing some rude cleanup"

# We don't link statically, so we don't need the largest .a files. We can't
# just remove all .a files, as some are required at compile time.
rm -f /usr/lib/llvm-*/lib/*.a
rm -f /usr/lib/{i386-linux-gnu,x86_64-linux-gnu}/{libicu*,libcrypto*,libssl*,libsystemd*,libperl*}.a

# We don't need man pages and docs. Removing them is mostly interesting to
# reduce container unpack times.
find /usr/share/doc -type f -exec rm '{}' +
find /usr/share/man -type f -exec rm '{}' +

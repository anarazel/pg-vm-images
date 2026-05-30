#! /bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

apt-get -y install --no-install-recommends \
   docbook-xml \
   docbook-xsl \
   fop \
   libxml2-utils \
   pandoc \
   wget \
   xsltproc

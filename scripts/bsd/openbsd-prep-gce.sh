#!/bin/sh

set -e

# Patch
syspatch

# Network
rm /etc/hostname.*
echo 'dhcp' > /etc/hostname.vio0

# Enable multithreading
echo 'hw.smt=1' > /etc/sysctl.conf

# Serial console
echo 'stty com0 115200' > /etc/boot.conf
echo 'set tty com0'    >> /etc/boot.conf
sed -i -e 's/^tty00[[:space:]]\(.*\)[[:space:]]unknown off$/tty00   \1   vt220   on  secure/' \
  /etc/ttys

# Update packages
pkg_add -uvI

# Install curl for startup & shutdown scripts
pkg_add -I curl

# Install sudo and then set its configuration to 'users can access sudo without password'
pkg_add -I sudo--
echo '%wheel ALL=(ALL) NOPASSWD: SETENV: ALL' | sudo EDITOR='tee -a' visudo

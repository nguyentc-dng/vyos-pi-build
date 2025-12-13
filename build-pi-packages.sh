#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)
PKG_DIR=$ROOTDIR/packages
OCAML_VERSION=4.14.2

cd $ROOTDIR
# Build vyos-1.x for RPI4
echo "Clone VyOS-1.x code"
cd $ROOTDIR/vyos-build/scripts/package-build/vyos-1x/
find . -maxdepth 1 ! -name "package.toml" ! -name "build.py" -exec rm -rf {} \;
git clone --recurse-submodules https://github.com/vyos/vyos-1x

# Patch vyos-1.x code for RPI console ttyAMA0
echo "Patch code Vyos-1.x for RPI4"
cd ./vyos-1x 
patch -p1 < $ROOTDIR/patches/vyos-1.x/vyos-1.x-rpi4-patches.diff
git add .
git config --global user.name "TCNGUYEN" && git config --global user.email "trancaonguyendn@gmail.com"
git commit -m "Fix code for RPI"
cd ../

# Build Vyos-1.x packages
echo "Build Vyos-1.x"
rm -rf /usr/lib/libvyosconfig.so.0
sysctl -w net.ipv4.conf.lo.forwarding=1
./build.py
find . -maxdepth 1 -type f -name "*.deb" | grep -E "^(./)?(libvyosconfig0_|vyos-1x_)" | xargs cp -t $ROOTDIR/packages

cd $ROOTDIR
# Build telegraf for RPI4
cd ./vyos-build/scripts/package-build/telegraf
rm -rf telegraf
./build.py
find . -maxdepth 1 -type f -name "*.deb" | grep -E "^(./)?(telegraf_)" | xargs cp -t $ROOTDIR/packages
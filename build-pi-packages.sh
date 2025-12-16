#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)
export OCAML_VERSION=4.14.2

# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "❌ERROR: You must run script with root privileges!"
    exit 1
fi

# Build vyos-1x for RPI4
cd ${ROOTDIR}/vyos-build/scripts/package-build/vyos-1x/
echo "Building Vyos-1x"
rm -rf /usr/lib/libvyosconfig.so.0
if [ ! -f /.dockerenv ]; then
    sysctl -w net.ipv4.conf.lo.forwarding=1
    sysctl -w net.ipv6.conf.lo.disable_ipv6=0
fi
./build.py
find ${ROOTDIR}/vyos-build/scripts/package-build/vyos-1x/ -maxdepth 1 -type f -name "*.deb" | grep -E "^(./)?(libvyosconfig0_|vyos-1x_)" | xargs -I {} cp {} ${ROOTDIR}/packages/
    
# Build telegraf for RPI4
cd ${ROOTDIR}/vyos-build/scripts/package-build/telegraf/
rm -rf telegraf
./build.py
find ${ROOTDIR}/vyos-build/scripts/package-build/telegraf/ -maxdepth 1 -type f -name "*.deb" | grep -E "^(./)?(telegraf_)" | xargs -I {} cp {} ${ROOTDIR}/packages/

# Return to ROOTDIR
cd ${ROOTDIR}

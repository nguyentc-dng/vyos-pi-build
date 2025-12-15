#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "❌ERROR: You must run script with root privileges!"
    exit 1
fi

# Build custom VyOS kernel for RPI
KERNEL_BRANCH_NAME=rpi-$(sed -n -e 's/^kernel_version = "\([^.]\+\.[^.]\+\)\..\+"$/\1/p' ${ROOTDIR}/vyos-build/data/defaults.toml).y
cd ${ROOTDIR}/vyos-build/scripts/package-build/linux-kernel/

echo "Build kernel for pi (${KERNEL_BRANCH_NAME})"
# Build kernel for RPI
./build.py --install-dependencies
./build-kernel.sh

# Orther kernel packages
echo "Build orther require kernel packages"
./build.py --packages linux-firmware accel-ppp-ng ovpn-dco nat-rtsp jool realtek-r8152 realtek-r8126 ipt-netflow 

# Copy built files
echo "Copying built packages"
find ${ROOTDIR}/vyos-build/scripts/package-build/linux-kernel/ -type f -name '*.deb' | \
    grep -e 'accel-ppp-ng_' -e 'linux-' -e 'vyos-' -e 'nat-rtsp_' -e 'openvpn-dco_' -e 'jool_' | \
    xargs -I {} cp {} ${ROOTDIR}/packages/

# Clean
rm -rf linux/ linux-firmware/ accel-ppp-ng/ ovpn-dco/ nat-rtsp/ jool/ realtek-r8152/ realtek-r8126/ ipt-netflow/

# Return to ROOTDIR
cd ${ROOTDIR}
#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "❌ You must run script with root privileges!"
    exit 1
fi

#export VYOS_BRANCH=$(git branch --show-current)
export VYOS_BRANCH="current"

VYOS_BUILD_TYPE="release"
VYOS_BUILD_BY="trancaonguyendn@gmail.com"
PIVERSION=4
DEVTREE="bcm2711-rpi-4-b"
#PIVERSION=3
#DEVTREE="bcm2711-rpi-cm4"
#DEVTREE="bcm2710-rpi-3-b"
#DEVTREE="bcm2710-rpi-3-b-plus"

# Clone Vyos-build repository and create required directory
VYOS_BUILD_TYPE=${VYOS_BUILD_TYPE} ./prepare.sh

# Build kernel for RPI
./build-pi-kernel.sh

# Build custom packages for RPI4
./build-pi-packages.sh

# Build VyOS RAW Image
VYOS_BUILD_TYPE=${VYOS_BUILD_TYPE} VYOS_BUILD_BY=${VYOS_BUILD_BY} ./build-vyos-image.sh

# Build u-boot
echo "Building u-boot for RPI${PIVERSION}"
PIVERSION=${PIVERSION} ./build-u-boot.sh

# Generate RPI image from the iso
VYOS_IMAGE=$(find ${ROOTDIR}/images/ -type f -name *.raw | head -n 1)
DEVTREE=${DEVTREE} PIVERSION=${PIVERSION} ./build-pi-image.sh ${VYOS_IMAGE}

# Clean up
./cleanup.sh

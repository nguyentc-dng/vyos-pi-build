#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

#export VYOS_BRANCH=$(git branch --show-current)
export VYOS_BRANCH="current"
export VYOS_BUILD_TYPE="release"
export VYOS_BUILD_BY="trancaonguyendn@gmail.com"

export PIVERSION=4
export DEVTREE="bcm2711-rpi-4-b"
#PIVERSION=3
#DEVTREE="bcm2711-rpi-cm4"
#DEVTREE="bcm2710-rpi-3-b"
#DEVTREE="bcm2710-rpi-3-b-plus"

# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "❌ERROR: You must run script with root privileges!"
    exit 1
fi

# Clone Vyos-build repository and create required directory
./prepare.sh

# Build kernel for RPI
./build-pi-kernel.sh

# Build custom packages for RPI4
./build-pi-packages.sh

# Build VyOS RAW Image
./build-vyos-image.sh

# Build u-boot
./build-u-boot.sh

# Generate RPI image from the iso
./build-pi-image.sh

# Clean up
./cleanup.sh

#!/bin/bash
if [ ! -z "${DEBUG}" ]; then
    set -x
fi
set -e
ROOTDIR=$(pwd)

# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "❌ERROR: You must run script with root privileges!"
    exit 1
fi

# Install require package 
sudo apt update && sudo apt install -y libgnutls28-dev

# build u-boot
echo "Building u-boot for PI${PIVERSION}"
cd u-boot
make -s rpi_${PIVERSION}_defconfig 
make -s -j $(getconf _NPROCESSORS_ONLN)

# Copy built u-boot bin
mv ./u-boot.bin ${ROOTDIR}/packages/u-boot-rpi${PIVERSION}.bin

# Return to ROOTDIR
cd ${ROOTDIR}

# Clean
rm -rf ./u-boot/

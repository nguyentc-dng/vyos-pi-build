#!/bin/bash
if [ ! -z "${DEBUG}" ]; then
    set -x
fi
set -e
ROOTDIR=$(pwd)

if [ ! -d "u-boot" ]; then
    git clone --depth=1 git://git.denx.de/u-boot.git
else
    echo "Using existing u-boot repository"
    EXIST="yes"
fi

(
    sudo apt update && sudo apt install libgnutls28-dev
    cd u-boot
    echo "Configuring u-boot for PI${PIVERSION}"
    make -s rpi_${PIVERSION}_defconfig 
    echo "Building u-boot for PI${PIVERSION}"
    make -s -j $(getconf _NPROCESSORS_ONLN)
)

mv ./u-boot/u-boot.bin ./packages/u-boot-rpi${PIVERSION}.bin

if [ -z "${EXIST}" ]; then
    echo "Cleaning up"
    rm -rf u-boot
fi

#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

# Check root user
if [ "$EUID" -ne 0 ]; then
    echo "❌ERROR: You must run script with root privileges!"
    exit 1
fi

# Create directory for packages and images 
echo "Create packages and images directory"
rm -rf ${ROOTDIR}/packages && mkdir -p ${ROOTDIR}/packages
rm -rf ${ROOTDIR}/images && mkdir -p ${ROOTDIR}/images

# Clean old vyos-build dir if exist and clone vyos-build
echo "Clean old vyos-build dir if exist and clone vyos-build"
rm -rf ${ROOTDIR}/vyos-build
git clone -b ${VYOS_BRANCH} https://github.com/vyos/vyos-build.git vyos-build
sed -i "s/build_type\ =.*/build_type\ =\ \"${VYOS_BUILD_TYPE}\"/g" ${ROOTDIR}/vyos-build/data/defaults.toml

# Clone RPI kernel and patch for VyOS 
cd ${ROOTDIR}/vyos-build/scripts/package-build/linux-kernel/
KERNEL_BRANCH_NAME=rpi-$(sed -n -e 's/^kernel_version = "\([^.]\+\.[^.]\+\)\..\+"$/\1/p' vyos-build/data/defaults.toml).y
echo "Download and patch Linux kernel for RPI "
rm -rf *.deb *.zip ./linux/
wget -nv https://github.com/raspberrypi/linux/archive/refs/heads/${KERNEL_BRANCH_NAME}.zip
unzip -q ${KERNEL_BRANCH_NAME}.zip && rm ${KERNEL_BRANCH_NAME}.zip
mv linux-${KERNEL_BRANCH_NAME}/ linux/
cd ./linux && KERNEL_VERSION=$(make kernelversion) && cd ../
sed -i "s/kernel_version\ =.*/kernel_version\ =\ \"${KERNEL_VERSION}\"/g" ${ROOTDIR}/vyos-build/data/defaults.toml
sed -i "s/kernel_flavor\ =.*/kernel_flavor\ =\ \"vyos-rpi\"/g" ${ROOTDIR}/vyos-build/data/defaults.toml
cp ${ROOTDIR}/patches/linux-kernel/config-vyos-rpi arch/arm64/configs/vyos_defconfig

# Clone and patch VyOS-1.x code for RPI
cd ${ROOTDIR}/vyos-build/scripts/package-build/vyos-1x/
echo "Clone and patch VyOS-1.x code for RPI"
find . -maxdepth 1 ! -name "package.toml" ! -name "build.py" -exec rm -rf {} \;
git clone --recurse-submodules https://github.com/vyos/vyos-1x
cd ./vyos-1x 
patch -p1 < ${ROOTDIR}/patches/vyos-1.x/vyos-1.x-rpi4-patches.diff
git add .
git config --global user.name "TCNGUYEN" && git config --global user.email "trancaonguyendn@gmail.com"
git commit -m "Fix code VyOS-1.x for RPI"

# Patch vyos-build scripts
cd ${ROOTDIR}/vyos-build/
echo "Patch vyos-build scripts"
cp ${ROOTDIR}/patches/vyos-build/config.boot.default ./data/live-build-config/includes.chroot/opt/vyatta/etc/config.boot.default
cp ${ROOTDIR}/patches/vyos-build/rpi4.toml ./data/build-flavors/rpi4.toml
cp ${ROOTDIR}/patches/vyos-build/arm64.toml ./data/architectures/arm64.toml

# Clone u-boot repository
cd ${ROOTDIR}
git clone --depth=1 git://git.denx.de/u-boot.git u-boot

# Return to ROOTDIR
cd ${ROOTDIR}

#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

#KERNEL_BRANCH_NAME=v$(sed -n -e 's/^kernel_version = "\(.*\)"$/\1/p' vyos-build/data/defaults.toml)
#KERNEL_REPO=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
KERNEL_BRANCH_NAME=rpi-$(sed -n -e 's/^kernel_version = "\([^.]\+\.[^.]\+\)\..\+"$/\1/p' vyos-build/data/defaults.toml).y
KERNEL_REPO=https://github.com/raspberrypi/linux

cd vyos-build/scripts/package-build/linux-kernel/

# Clean old packages
echo "Clean old packages"
rm -rf *.deb *.zip

echo "Build kernel for pi (${KERNEL_BRANCH_NAME})"
# Clone kernel repo
rm -rf linux/
#git clone -b ${KERNEL_BRANCH_NAME} ${KERNEL_REPO}
wget -nv https://github.com/raspberrypi/linux/archive/refs/heads/${KERNEL_BRANCH_NAME}.zip
unzip -q ${KERNEL_BRANCH_NAME}.zip && rm ${KERNEL_BRANCH_NAME}.zip
mv linux-${KERNEL_BRANCH_NAME}/ linux/

# Patch vyos-build config
cd linux && KERNEL_VERSION=$(make kernelversion) && cd ../
sed -i "s/kernel_version\ =.*/kernel_version\ =\ \"${KERNEL_VERSION}\"/g" ${ROOTDIR}/vyos-build/data/defaults.toml
sed -i "s/kernel_flavor\ =.*/kernel_flavor\ =\ \"vyos-rpi\"/g" ${ROOTDIR}/vyos-build/data/defaults.toml
cp ${ROOTDIR}/patches/linux-kernel/config-vyos-rpi arch/arm64/configs/vyos_defconfig
#cp linux/arch/arm64/configs/bcm2711_defconfig arch/arm64/configs/vyos_defconfig
#patch --forward -t -u arch/arm64/configs/vyos_defconfig < ${ROOTDIR}/patches/linux-kernel/0001_bcm2711_defconfig.patch

# Build kernel for RPI
./build.py --install-dependencies
./build-kernel.sh

# Orther kernel packages
echo "Build orther require kernel packages"
./build.py --packages linux-firmware accel-ppp-ng ovpn-dco nat-rtsp jool realtek-r8152 realtek-r8126 ipt-netflow 

# Copy built files
echo "Copying built packages"
find ./ -type f -name '*.deb' | \
       grep -e 'accel-ppp-ng_' -e 'linux-' -e 'vyos-' -e 'nat-rtsp_' -e 'openvpn-dco_' -e 'jool_' | \
       xargs -I {} cp {} ${ROOTDIR}/packages/

cd ${ROOTDIR}

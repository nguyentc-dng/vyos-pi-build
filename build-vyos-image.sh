#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

# Copy prebuilt package
echo "Copy prebuilt packages"
rm -rf vyos-build/packages/*
for a in $(find ./packages/ -type f -name "*.deb" | grep -v -e "-dbgsym_" -e "libnetfilter-conntrack3-dbg"); do
	echo "Copying package: $a"
	cp $a ./vyos-build/packages/
done

cd vyos-build

#copy default config
echo "Copy new default configuration to the vyos image"
cp ${ROOTDIR}/patches/vyos-build/config.boot.default ./data/live-build-config/includes.chroot/opt/vyatta/etc/config.boot.default

# Copy build flavor for RPI4
echo "Copy build-flavor file for RPI4"
cp ${ROOTDIR}/patches/vyos-build/rpi4.toml ./data/build-flavors/rpi4.toml

# Patch arm64.toml for openvpn-dco and telegraf
cp ${ROOTDIR}/patches/vyos-build/arm64.toml ./data/architectures/arm64.toml

# Build the image
make clean
export VYOS1X_REPO_URL=file:///${ROOTDIR}/vyos-build/scripts/package-build/vyos-1x/vyos-1x
./build-vyos-image rpi4 --architecture arm64 --build-by "${VYOS_BUILD_BY}" --build-type "${VYOS_BUILD_TYPE}"

cd ${ROOTDIR}

# Check ISO file
LIVE_IMAGE=$(find ./vyos-build/build/ -type f -name *.raw | head -n 1)

if [ ! -e ${LIVE_IMAGE} ]; then
	echo "File ${LIVE_IMAGE} not exists."
	exit -1
else
	cp ${LIVE_IMAGE} ${ROOTDIR}/images/
fi
